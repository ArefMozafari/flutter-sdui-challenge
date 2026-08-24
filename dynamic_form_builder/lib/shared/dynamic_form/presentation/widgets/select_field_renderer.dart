import 'package:flutter/material.dart';

import 'package:dynamic_form_builder/core/design_system/components/ds_select.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/field_size_hint_mapping.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/validation_message_resolver.dart';

class SelectFieldRenderer extends StatelessWidget {
  const SelectFieldRenderer({
    super.key,
    required this.spec,
    required this.value,
    required this.error,
    required this.onChanged,
    this.enabled = true,
  });

  final SelectFieldSpec spec;
  final SelectValue value;
  final ValidationResult? error;
  final ValueChanged<FieldValue> onChanged;

  /// False while a submit is in flight, so the values being sent can't
  /// change underneath the request.
  final bool enabled;

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
      enabled: enabled,
    );
  }
}
