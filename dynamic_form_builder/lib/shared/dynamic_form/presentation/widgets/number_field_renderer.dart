import 'package:flutter/material.dart';

import 'package:dynamic_form_builder/core/design_system/components/ds_text_field.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/field_size_hint_mapping.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/validation_message_resolver.dart';

/// Renders a [NumberFieldSpec] as a text field constrained to a numeric
/// keyboard. Text that doesn't parse as a number becomes `NumberValue(null)`
/// rather than a distinct "invalid number" state — a simplification: the
/// `validationInvalidNumber` key exists for a future stricter mode, but
/// today an unparsable number is caught by `required` at submit time like
/// any other empty field, not flagged as a separate parse error while
/// typing.
///
/// Parsing goes through [parseLocalizedNumber], not `num.tryParse` directly —
/// see that function for why a `fa`-default app can't use the bare one.
class NumberFieldRenderer extends StatelessWidget {
  const NumberFieldRenderer({
    super.key,
    required this.spec,
    required this.value,
    required this.error,
    required this.onChanged,
    this.enabled = true,
  });

  final NumberFieldSpec spec;
  final NumberValue value;
  final ValidationResult? error;
  final ValueChanged<FieldValue> onChanged;

  /// False while a submit is in flight, so the values being sent can't
  /// change underneath the request.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DsTextField(
      label: spec.label,
      onChanged: (text) => onChanged(NumberValue(parseLocalizedNumber(text))),
      initialValue: value.number?.toString(),
      hintText: spec.placeholder,
      errorText: resolveValidationMessage(l10n, error),
      isRequired: spec.validation.required,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      size: spec.sizeHint.toDs,
      enabled: enabled,
    );
  }
}

/// Zero digits of the numeral systems an Arabic-script keyboard produces,
/// paired with the ASCII zero they map onto. Each system's ten digits are
/// contiguous from its zero, so an offset from one of these is all it takes.
const _localizedZeros = [
  0x06F0, // Extended Arabic-Indic (Persian/Urdu): ۰۱۲۳۴۵۶۷۸۹
  0x0660, // Arabic-Indic: ٠١٢٣٤٥٦٧٨٩
];

const _asciiZero = 0x30;
const _asciiDot = 0x2E;
const _arabicDecimalSeparator = 0x066B; // ٫

/// Parses what the user actually typed, which is not necessarily ASCII.
///
/// `num.tryParse` accepts ASCII digits only, so on a Persian keyboard — the
/// default input for this app's default locale — every number field silently
/// read as empty: the field showed `۲۰۱۹` while validation reported it
/// missing. Normalizing first is what makes a number field usable in `fa`
/// at all.
///
/// Done by hand rather than through `intl`'s `NumberFormat` because the
/// failure isn't tied to the app's locale: a Persian keyboard can be used
/// while the UI is in `en`, and a locale-bound parser would reject those
/// digits exactly as `num.tryParse` does. This accepts either numeral system
/// whichever locale happens to be active.
///
/// Grouping separators are still not handled, in either script — `1,000`
/// doesn't parse today and `۱٬۰۰۰` doesn't either, which keeps the two
/// consistent rather than making one script quietly more capable.
num? parseLocalizedNumber(String text) {
  final normalized = StringBuffer();
  for (final rune in text.trim().runes) {
    normalized.writeCharCode(_normalizeRune(rune));
  }
  return num.tryParse(normalized.toString());
}

int _normalizeRune(int rune) {
  if (rune == _arabicDecimalSeparator) return _asciiDot;
  for (final zero in _localizedZeros) {
    if (rune >= zero && rune <= zero + 9) return _asciiZero + (rune - zero);
  }
  return rune;
}
