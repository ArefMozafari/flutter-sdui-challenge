# Dynamic Form Builder

Server-driven dynamic form: fetches a form's structure, renders text/number/multiline/select/file
fields, validates client-side, and submits it — including file uploads — back to the server. Built
for the challenge in [task/README.md](task/README.md).

- [AI usage](ai-usage-notes.html) — The real AI session log, Open in **browser** please.
- [ARCHITECTURE.md](ARCHITECTURE.md)

## Running it

The Flutter app lives in `dynamic_form_builder/`:

```bash
cd dynamic_form_builder
flutter pub get
flutter gen-l10n      # generates lib/core/l10n/app_localizations*.dart
flutter run
```

## Design system

`core/design_system/` — tokens → theme → five reusable components (`DsTextField`, `DsSelect`,
`DsFilePicker`, `DsButton`, `DsFieldLabel`). Server style hints resolve to the nearest token before
reaching a widget; nothing inlines a raw color or spacing value.

## Localization

`fa` (default, RTL) and `en`, via Flutter's ARB pipeline. Validation and failure messages are
localization **keys**, not strings — Domain and Data never import `BuildContext` or `intl`.

## Tests

One suite per layer — Domain, Data, Application, Presentation — plus a full widget-tree flow through
`DynamicFormView` (fill, submit, see the result). `flutter test` runs all of them.

## Vocabulary

Naming conventions and abbreviations used throughout the codebase:

| Term | Meaning |
|---|---|
| **SDUI** | Server-Driven UI — the server sends structure, the client renders it. |
| **`Ds` prefix** | Design System — marks every component the design system owns, so it's never confused with a Flutter/Material widget. |
| **DTO** | Data Transfer Object — a wire-shaped type (`FormSpecDto`), mapped into a Domain model rather than used outside Data. |
| **ARB** | Application Resource Bundle — the JSON format Flutter's localization tooling reads to generate `AppLocalizations`. |
| **`Failure`** | Domain's sealed type for everything that can go wrong (network, timeout, server, parse, unexpected) — never a raw exception past the Repository. |
| **`Either<Failure, T>`** | fpdart's two-in-one type: a `Failure` or a successful `T`. Forces every caller to handle failure. |
| **Sealed class** | A Dart 3 hierarchy closed outside its own file — every `switch` over it is exhaustiveness-checked at compile time. |
| **`FieldSizeHint` vs. `DsFieldSize`** | Same three sizes, two enums — Domain's and the design system's — mapped by Presentation. |
| **`SelectedFile` vs. `SubmissionFile`** | Same picked file at two layers: Domain groups it implicitly by field; Data's flat list carries the field name explicitly. |
