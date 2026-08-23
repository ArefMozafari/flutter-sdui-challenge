# dynamic_form_builder

A server-driven dynamic form: the app fetches a form's structure from a
server, renders text/number/multiline/select/file fields from it, validates
client-side, and submits the result — including file uploads — back to the
server. Built for the take-home challenge described in the [repo root
README](../README.md); this file covers the Flutter app itself.

## Running it

```bash
flutter pub get
flutter gen-l10n                                              # generates lib/core/l10n/app_localizations*.dart
dart run build_runner build --delete-conflicting-outputs      # generates *.g.dart (Riverpod)
flutter run
```

Both generation steps are gitignored outputs — `flutter pub get` triggers
the first automatically; the second needs the explicit `build_runner`
invocation above. `flutter analyze && flutter test` is the verify command.

There's no real backend: `MockDynamicFormDataSource` serves
`assets/mock/car_listing_form.json` in place of a network call, with
configurable latency and injectable failure modes (network/timeout/
server-500/malformed-body) so every error state has something real behind
it. Swapping to a real backend is one line, in `lib/app/di.dart`.

## Architecture

Four layers — Presentation, Application, Data, Domain — with Domain as the
one node everything else is allowed to depend on:

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

Domain depends on nothing. Data and Application both depend inward on
Domain — that's the one direction allowed regardless of which side of
Domain a layer sits on. Nothing in Domain or Data ever imports Application
or Presentation.

### Folder layout: `core` / `shared` / `features`

```
lib/
├── app/                # MaterialApp, theme, l10n wiring, provider overrides (di.dart)
├── core/                # generic infra with zero domain knowledge — could ship in any app unchanged
│   ├── design_system/   # tokens → theme → components
│   ├── network/          # ApiClient (dio) — transport only
│   └── l10n/
├── shared/               # domain-aware, but consumed by more than one feature
│   └── dynamic_form/
│       ├── domain/       # pure Dart, zero imports outside itself
│       ├── data/         # depends on: domain only
│       ├── application/  # depends on: domain, data
│       └── presentation/ # depends on: application, domain
└── features/             # would hold single-owner pages/flows; empty in this challenge
```

Three buckets, told apart by two questions — *does it know this app's
business domain?* and *is it owned by one place, or consumed by several?*

| | knows the domain? | owned by one place? |
|---|---|---|
| `core/` | No | — |
| `shared/` | Yes | No — consumed by 2+ features |
| `features/` | Yes | Yes |

`dynamic_form` lives in `shared/`, not `features/`: it's meant to be
embedded across multiple pages of the app this challenge stands in for (a
survey app collecting data on several subjects), not owned by one page.
That's also why its Presentation layer ends at `DynamicFormView` — a
composable widget, not a routed `DynamicFormPage`. `app/`'s home page is
the one page in this repo that hosts it, same role a real subject page
would play.

### Skipping a layer

A caller may call straight past a middle layer to the one below it only
when the skipped layer would add nothing but delegation — never upward,
ever. `DynamicFormController` calls `DynamicFormRepository` directly for
`fetchForm` (a Service method here would be a one-line delegate) but goes
through `DynamicFormService` for `submitForm`, which validates-then-
short-circuits and translates Domain-shaped input into Data-shaped
`SubmissionFile`s — real work a Service earns its keep doing.

### Other decisions worth knowing before reading the code

- **`DynamicFormRepository` has no abstract interface; `DynamicFormDataSource`
  does.** Repository has exactly one implementation — Dart classes are
  implicitly their own interface, so a test fake needs no separate
  `abstract class`. DataSource genuinely has two real implementations
  (`MockDynamicFormDataSource`, `HttpDynamicFormDataSource`) that must be
  swappable at runtime via one Riverpod provider override — that's where
  the abstraction earns its cost.
- **Sealed classes end-to-end**: `FormFieldSpec`, `FieldValue`, `Failure`,
  `ValidationResult`, `DynamicFormViewState` are all sealed. Add a case and
  every `switch` touching it fails to compile until handled — except:
- **`FieldWidgetRegistry` is a runtime `Map`, deliberately not a `switch`.**
  The one place that exhaustiveness rule is broken on purpose: an
  `UnsupportedFieldSpec` (a server field type this build doesn't recognize)
  degrades to a visible placeholder in debug / silently skipped in release,
  instead of crashing or failing to compile.
- **No `freezed`.** Dart 3's native sealed classes cover every union type
  here; hand-written `fromJson` keeps the unknown-field-type fallback
  readable instead of hidden in generated code.
- **The legacy payload compatibility shim is structural only.** The
  README's original sample response (`assets/mock/legacy_form.json`) still
  parses — the shim flattens its `type: input` + `props.type` nesting and
  promotes whatever validation-relevant data `props` actually carries. It
  does not attempt to reconstruct `props.color` or `style.borderRadius`
  into anything; those are pure presentation noise with no Domain concept
  to map onto, and are simply dropped.
- **`HttpDynamicFormDataSource` is untested.** It exists so "DataSource has
  two real implementations" is true rather than hypothetical, but there's
  no real backend in this challenge to run it against, and a Dio-mocking
  test would only re-assert its own logic back at itself.
- **Number field parsing is a documented simplification.** Text that
  doesn't parse as a number becomes an empty value rather than a distinct
  "invalid number" error — caught by the `required` check at submit time
  like any other empty field, not flagged while typing.

## Design system

`core/design_system/` — tokens (spacing, radius, typography, color,
motion) → a `ThemeData` derived from them → five reusable components
(`DsTextField`, `DsSelect`, `DsFilePicker`, `DsButton`, `DsFieldLabel`).
Every field renderer in `shared/dynamic_form/presentation/widgets/` wraps
one of these — the design system never imports `dynamic_form`, and
`dynamic_form` never inlines a raw color or spacing value.

Server-declared style hints (`style.size`, or a legacy field's raw CSS)
never reach a widget as-is: `ServerStyleResolver` (Data layer) resolves
them into a Domain `FieldSizeHint`, which Presentation maps onto the
design system's own `DsFieldSize` — see
`shared/dynamic_form/presentation/widgets/field_size_hint_mapping.dart`.

## Localization

`fa` (default, RTL) and `en`, via Flutter's official ARB pipeline
(`lib/core/l10n/*.arb` → `flutter gen-l10n`). Every validation message and
failure Domain/Data can produce is a localization **key**, not a string —
Domain and Data stay free of `BuildContext`/`intl` imports entirely.
Presentation reconnects the key to real text:
`validation_message_resolver.dart` and `failure_message_resolver.dart`
switch on the key/`Failure` type to call the right generated
`AppLocalizations` method, since those generated methods are strongly
typed and can't be called by string key.

## Tests

Unit tests sit next to the layer they cover — Domain (models, validation,
failures), Data (DTO parsing including the legacy shim, style resolution,
repository), Application (submit orchestration), Presentation (controller
state transitions, and full widget-tree interaction through
`DynamicFormView`: fill a field, pick a dropdown option, submit, see the
result). `flutter test` runs all of them.

## Vocabulary

Naming conventions and abbreviations used throughout the codebase:

| Term | Meaning |
|---|---|
| **SDUI** | Server-Driven UI — the server sends structure, the client renders it, rather than the UI being hard-coded per screen. |
| **`Ds` prefix** | Design System — every reusable component the design system owns (`DsTextField`, `DsButton`, …) is prefixed so it's never confused with a Flutter/Material widget of a similar name. |
| **DTO** | Data Transfer Object — a type shaped for the wire (`FormSpecDto`, `FormFieldSpecDto`), mapped into a Domain model rather than used directly outside the Data layer. |
| **ARB** | Application Resource Bundle — the JSON format Flutter's official localization tooling reads (`app_en.arb`, `app_fa.arb`) to generate `AppLocalizations`. |
| **`Failure`** | Domain's sealed type for everything that can go wrong fetching/submitting a form (network, timeout, server, parse, unexpected) — never a raw exception past the Repository boundary. |
| **`Either<Failure, T>`** | From `fpdart` — a value that's one of two types, here always "a `Failure`, or the successful `T`." Forces every caller to handle the failure case; there's no way to accidentally ignore it the way a nullable return or a swallowed exception allows. |
| **Sealed class** | A Dart 3 class hierarchy closed to subtyping outside its own file — every `switch` over it is checked for exhaustiveness at compile time. Used for every closed set of variants in this codebase (`FormFieldSpec`, `Failure`, `ValidationResult`, `DynamicFormViewState`). |
| **`FieldSizeHint` vs. `DsFieldSize`** | Two separate enums for the same three sizes — `FieldSizeHint` is Domain's (knows nothing about the design system), `DsFieldSize` is the design system's (knows nothing about forms). Presentation maps between them; see "Design system" above. |
| **`SelectedFile` vs. `SubmissionFile`** | Both represent a picked file with real bytes, at different layers — `SelectedFile` (Domain) is grouped implicitly by its field in a `Map<String, FieldValue>`; `SubmissionFile` (Data) is the flat, wire-ready list `submitForm` sends across every field at once, so it carries its field name explicitly. |
