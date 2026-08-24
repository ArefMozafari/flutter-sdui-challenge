# Architecture

Full breakdown of the "RiverPod Architecture" behind `dynamic_form_builder/lib/` — the
summary in [README.md](README.md) links here for the reasoning behind each structural
decision.

## Dependency shape

Four layers — Presentation, Application, Data, Domain — with Domain as the one node
everything else is allowed to depend on:

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

## Folder layout: `core` / `shared` / `features`

```
lib/
├── app/                # MaterialApp, theme, l10n wiring — no providers of its own (see below)
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

## Skipping a layer

A caller may call straight past a middle layer to the one below it only
when the skipped layer would add nothing but delegation — never upward,
ever. `DynamicFormController` calls `DynamicFormRepository` directly for
`fetchForm` (a Service method here would be a one-line delegate) but goes
through `DynamicFormService` for `submitForm`, which validates-then-
short-circuits and translates Domain-shaped input into Data-shaped
`SubmissionFile`s — real work a Service earns its keep doing.

## Provider colocation

Every `*Provider` is declared at the top of the file that defines the class
it constructs, immediately above that class — never centralized into one
`providers.dart`/`di.dart`. `Command+Click` on a provider used anywhere in
the codebase lands you directly on the thing it provides, zero hops. The
one case that can't colocate with "the" class is
`dynamicFormDataSourceProvider`: `DynamicFormDataSource` is abstract with
two real implementations, so there's no single class to colocate with. It's
declared beside the abstract definition itself (`dynamic_form_datasource.dart`)
rather than either implementation — `Command+Click` lands beside the
interface, and its own doc comment says exactly which line to change to go
live. `DynamicFormController` used `@riverpod` code-gen briefly; it's
hand-written now for the same zero-hop reason and to keep this rule
exception-free everywhere except the one abstract case above.

`dynamicFormDataSourceProvider` briefly was a `Provider.family` keyed by an
enum naming the same two implementations again — reverted, since nothing
in this app ever watches the *other* branch: there's exactly one caller,
and it always wants whichever implementation the provider body currently
returns. A plain provider body is exactly as swappable with far less
machinery.

`DynamicFormDataSource` stays plain `abstract`, not `sealed`, even though
every other closed set of variants in this codebase is sealed — that's a
real constraint, not a style choice: `sealed` restricts `extends`/
`implements` to the declaring library, and every test fake
(`class _FakeDataSource implements DynamicFormDataSource`) lives in a test
file, a different library. Sealing this class would make every one of
those fakes a compile error.

## Other decisions worth knowing before reading the code

- **`DynamicFormRepository` has no abstract interface; `DynamicFormDataSource`
  does.** Repository has exactly one implementation — Dart classes are
  implicitly their own interface, so a test fake needs no separate
  `abstract class`. DataSource genuinely has two real implementations
  (`MockDynamicFormDataSource`, `HttpDynamicFormDataSource`) that must be
  swappable at runtime — that's where the abstraction earns its cost.
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
  original challenge's sample response (`assets/mock/legacy_form.json`,
  see [task/README.md](task/README.md)) still parses — the shim flattens
  its `type: input` + `props.type` nesting and promotes whatever
  validation-relevant data `props` actually carries. It does not attempt
  to reconstruct `props.color` or `style.borderRadius` into anything;
  those are pure presentation noise with no Domain concept to map onto,
  and are simply dropped.
- **`HttpDynamicFormDataSource`'s network calls are untested; its request
  building is.** There's no real backend in this challenge to run the
  actual `get`/`postMultipart` calls against. But `buildSubmitFormData` —
  turning `fields`/`files` into a multipart body — is pure Dart with no
  I/O, so it's extracted to a top-level function and tested directly. That
  test is what it looks like to take "there's nothing to test here"
  seriously rather than as an excuse: the untested first version of this
  file added files to the request as repeated `fieldName: file` map
  entries, which silently kept only the *last* file for any field that
  allows more than one (`car_images` allows up to 10) — a Dart map literal
  drops earlier entries for a duplicate key. The test would have caught it
  immediately; it does now if it regresses.
- **Number field parsing is a documented simplification.** Text that
  doesn't parse as a number becomes an empty value rather than a distinct
  "invalid number" error — caught by the `required` check at submit time
  like any other empty field, not flagged while typing.
