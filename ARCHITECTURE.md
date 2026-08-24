# Architecture

Full breakdown behind `dynamic_form_builder/lib/` — see [README.md](README.md) for the summary.

## Dependency shape

Four layers, with Domain as the one node everything else depends on:

```
   Presentation
        │    ╲
        │      ╲ (fetch — see "Skipping a layer" below)
        ▼        ╲
   Application ─────┐
        │            │
        ▼            ▼
      Data ───────► Domain
```

Domain depends on nothing; Data and Application both depend inward on it. Nothing in Domain or
Data ever imports Application or Presentation.

## Folder layout: `core` / `shared` / `features`

```
lib/
├── app/                # MaterialApp, theme, l10n wiring
├── core/                # domain-agnostic infra — could ship in any app unchanged
│   ├── design_system/   # tokens → theme → components
│   ├── network/          # ApiClient (dio) — transport only
│   └── l10n/
├── shared/               # domain-aware, consumed by more than one feature
│   └── dynamic_form/
│       ├── domain/       # zero imports outside itself
│       ├── data/         # depends on: domain only
│       ├── application/  # depends on: domain, data
│       └── presentation/ # depends on: application, domain
└── features/             # single-owner pages/flows; empty in this challenge
```

Told apart by two questions: does it know this app's domain, and is it owned by one place or
several? `dynamic_form` lives in `shared/` — it's meant to be embedded across multiple pages of
the survey app this challenge stands in for, not owned by one. That's why its Presentation layer
ends at the composable `DynamicFormView`, not a routed page.

## Skipping a layer

A caller may call straight past a middle layer that adds nothing but delegation — never upward.
`DynamicFormController` calls `DynamicFormRepository` directly for `fetchForm` (a Service method
would be a one-line delegate), but goes through `DynamicFormService` for `submitForm`, which
validates and translates Domain-shaped input into Data-shaped `SubmissionFile`s — real work.

## Provider colocation

Every `*Provider` sits above the class it constructs, in the same file — `Command+Click` always
lands on the implementation, never a central `di.dart`. The one exception,
`dynamicFormDataSourceProvider`, sits beside the abstract `DynamicFormDataSource` instead, since
that has two real implementations and no single class to colocate with.

It was briefly a `Provider.family` keyed by an enum — reverted, since nothing in the app ever
watches the other branch; one plain provider body is just as swappable. `DynamicFormDataSource`
stays plain `abstract`, not `sealed`, because `sealed` restricts `implements` to the declaring
library, and every test fake lives in a different one.

## Other decisions worth knowing before reading the code

- **`DynamicFormRepository` has no interface; `DynamicFormDataSource` does.** Repository has one
  implementation (Dart classes are their own interface); DataSource has two real ones that must
  be swappable at runtime.
- **Sealed classes end-to-end** (`FormFieldSpec`, `FieldValue`, `Failure`, `ValidationResult`,
  `DynamicFormViewState`, `SubmitStatus`) — except `FieldWidgetRegistry`, a runtime `Map` on
  purpose: an unrecognized field type degrades to a placeholder instead of failing to compile.
  Being precise about what that buys, since the fallback used to promise more than it delivered:
  the graceful path for an unknown *wire* type comes from Domain modelling it as an
  `UnsupportedFieldSpec`, which a `switch` would handle identically. What the `Map` trades away
  is the compile error for a *known* subtype with no entry — a case that used to throw a
  `TypeError` on screen and now renders a placeholder, but still leaves that field validated and
  invisible, so a required one would block submit. A missing entry has to be caught in review.
- **Submit state is one sealed `SubmitStatus`, not a set of flags — reversed on evidence.** This
  file used to argue that sub-sealing `DynamicFormLoaded` would multiply into a
  loaded × submitting × error cross product for no benefit. It wouldn't: the four flags
  (`isSubmitting`, `submitSucceeded`, `submitFailure`, `fieldErrors`) were never independent, so
  there was no cross product — just a five-case union written the long way. Because every
  transition rebuilt the state object from scratch, an unmentioned flag reverted to its default,
  and `updateValue` not mentioning `isSubmitting` let an edit cancel an in-flight submit
  (double-submit, then lost input). One field that must be set beats four that can be forgotten.
- **A form is frozen while its submit is in flight.** The view passes `enabled: false` to every
  renderer and `updateValue` refuses writes, so the payload a request carries can't disagree with
  what was on screen when the result lands. Belt and braces on purpose: the view lock is the UX,
  the controller guard is the guarantee.
- **No `freezed`.** Native sealed classes cover every union here; hand-written `fromJson` keeps
  the unknown-type fallback readable instead of hidden in generated code.
- **The legacy payload shim is structural only.** The original sample response (see
  [task/README.md](task/README.md)) still parses, but raw CSS like `props.color` is simply
  dropped — no Domain concept to map it onto.
- **`HttpDynamicFormDataSource`'s network calls are untested; its request building is.** No real
  backend exists here, but `buildSubmitFormData` is pure Dart and tested directly — that test is
  what caught a real bug where duplicate map keys silently dropped all but the last file per field.
- **Number field parsing is a documented simplification.** Unparseable text becomes empty, caught
  by the `required` check at submit time rather than a distinct "invalid number" error.
- **What counts as parseable is not ASCII-only.** `parseLocalizedNumber` normalizes Persian and
  Arabic-Indic digits before `num.tryParse`, which rejects them outright. Without it a number
  field can't be filled from the keyboard this app's own default locale implies — found by
  running the app in `fa`, not by a test.
