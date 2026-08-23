import 'package:flutter/material.dart';

import '../../../../core/design_system/components/ds_text_field.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/field_value.dart';
import '../../domain/models/form_field_spec.dart';
import '../../domain/validation/validation_result.dart';
import 'field_size_hint_mapping.dart';
import 'validation_message_resolver.dart';

/// Renders a [NumberFieldSpec] as a text field constrained to a numeric
/// keyboard. Text that doesn't parse as a number becomes `NumberValue(null)`
/// rather than a distinct "invalid number" state — a simplification: the
/// `validationInvalidNumber` key exists for a future stricter mode, but
/// today an unparsable number is caught by `required` at submit time like
/// any other empty field, not flagged as a separate parse error while
/// typing.
class NumberFieldRenderer extends StatelessWidget {
  const NumberFieldRenderer({
    super.key,
    required this.spec,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final NumberFieldSpec spec;
  final NumberValue value;
  final ValidationResult? error;
  final ValueChanged<FieldValue> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DsTextField(
      label: spec.label,
      onChanged: (text) => onChanged(NumberValue(num.tryParse(text.trim()))),
      initialValue: value.number?.toString(),
      hintText: spec.placeholder,
      errorText: resolveValidationMessage(l10n, error),
      isRequired: spec.validation.required,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      size: spec.sizeHint.toDs,
    );
  }
}
