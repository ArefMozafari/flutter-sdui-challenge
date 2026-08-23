import 'package:flutter/material.dart';

import '../../../../core/design_system/components/ds_select.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/field_value.dart';
import '../../domain/models/form_field_spec.dart';
import '../../domain/validation/validation_result.dart';
import 'field_size_hint_mapping.dart';
import 'validation_message_resolver.dart';

class SelectFieldRenderer extends StatelessWidget {
  const SelectFieldRenderer({
    super.key,
    required this.spec,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final SelectFieldSpec spec;
  final SelectValue value;
  final ValidationResult? error;
  final ValueChanged<FieldValue> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DsSelect<String>(
      label: spec.label,
      options: [
        for (final option in spec.options)
          DsSelectOption(label: option.label, value: option.value),
      ],
      value: value.value,
      onChanged: (selected) => onChanged(SelectValue(selected)),
      errorText: resolveValidationMessage(l10n, error),
      isRequired: spec.validation.required,
      size: spec.sizeHint.toDs,
    );
  }
}
