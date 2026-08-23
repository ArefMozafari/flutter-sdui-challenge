import '../../../../core/l10n/app_localizations.dart';
import '../../domain/validation/validation_result.dart';

/// Resolves a Domain [ValidationResult]'s key + args into real text via the
/// generated [AppLocalizations] methods.
///
/// Can't be a lookup table: the generated methods are strongly typed
/// (`validationMinLength(int)`, `validationMax(num)`, ...), not callable by
/// string key — Dart has no reflection for that. This switch is the one
/// place typing gets reconnected to the string key Domain emits. Matching
/// [ValidationResult]'s key/args shape is on this function: if
/// `field_validator.dart` ever adds a new key, this switch needs a new
/// case too — that coupling is *why* Domain returns a plain string key
/// rather than something more strongly typed: it's cheaper to keep in sync
/// here than to give Domain its own localization API.
String? resolveValidationMessage(
  AppLocalizations l10n,
  ValidationResult? result,
) {
  if (result is! InvalidResult) return null;
  final args = result.args;
  return switch (result.messageKey) {
    'validationRequired' => l10n.validationRequired,
    'validationMinLength' => l10n.validationMinLength(args['min']! as int),
    'validationMaxLength' => l10n.validationMaxLength(args['max']! as int),
    'validationMin' => l10n.validationMin(args['min']! as num),
    'validationMax' => l10n.validationMax(args['max']! as num),
    'validationFileTooLarge' => l10n.validationFileTooLarge(
      args['maxSize']! as String,
    ),
    'validationTooManyFiles' => l10n.validationTooManyFiles(
      args['max']! as int,
    ),
    'validationUnsupportedFileType' => l10n.validationUnsupportedFileType,
    _ => l10n.errorGeneric,
  };
}
