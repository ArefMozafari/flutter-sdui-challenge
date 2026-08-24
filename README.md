# dynamic_form_builder

A server-driven dynamic form: the app fetches a form's structure from a
server, renders text/number/multiline/select/file fields from it, validates
client-side, and submits the result — including file uploads — back to the
server. Built for the take-home challenge described in [task/README.md](task/README.md).

## Running it

The Flutter app lives in `dynamic_form_builder/`:

```bash
cd dynamic_form_builder
flutter pub get
flutter gen-l10n      # generates lib/core/l10n/app_localizations*.dart
flutter run
```

## Architecture

Four layers — Presentation, Application, Data, Domain — Riverpod-wired, with Domain as the
one node everything else depends on and nothing depends out of. Code splits into `core`
(domain-agnostic infra), `shared` (domain-aware, multi-consumer — this challenge's one
module, `dynamic_form`), and `features` (single-owner pages, empty here). A caller may skip
a middle layer that adds nothing but delegation, never upward; each Riverpod provider is
declared beside the class it constructs.

Full dependency diagram, folder layout, the layer-skip and provider-colocation rules, and
the architecture-level decisions worth knowing before reading the code:
[ARCHITECTURE.md](ARCHITECTURE.md).

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
repository, and `HttpDynamicFormDataSource`'s multipart body construction),
Application (submit orchestration), Presentation (controller state
transitions, and full widget-tree interaction through `DynamicFormView`:
fill a field, pick a dropdown option, submit, see the result).
`flutter test` runs all of them.

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
