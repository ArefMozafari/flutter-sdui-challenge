/// The outcome of validating one field's [FieldValue] against its
/// [FieldValidation] rules.
///
/// `invalid` carries a localization **key**, not a message string — Domain
/// must stay pure Dart with zero `BuildContext`/`intl` imports, so it can't
/// produce user-facing text itself. Presentation resolves the key (plus
/// [args] for placeholders like `{min}`) through `AppLocalizations`. This
/// is also what makes fa/en both fall out for free: one key, two arb
/// translations, no duplicated validation logic per locale.
sealed class ValidationResult {
  const ValidationResult();

  const factory ValidationResult.valid() = ValidResult;

  const factory ValidationResult.invalid(
    String messageKey, {
    Map<String, String> args,
  }) = InvalidResult;

  bool get isValid => this is ValidResult;
}

final class ValidResult extends ValidationResult {
  const ValidResult();
}

final class InvalidResult extends ValidationResult {
  const InvalidResult(this.messageKey, {this.args = const {}});

  /// An `AppLocalizations` message key, e.g. `validationMinLength`.
  final String messageKey;

  /// Placeholder values for the message, e.g. `{'min': '2'}`.
  final Map<String, String> args;
}
