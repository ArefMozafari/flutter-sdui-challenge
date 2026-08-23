import 'package:flutter/material.dart';

import 'package:dynamic_form_builder/core/design_system/components/ds_text_field.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/field_size_hint_mapping.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/validation_message_resolver.dart';

/// Renders both [TextFieldSpec] and [MultilineFieldSpec] — same widget
/// (`DsTextField`), same value type ([TextValue]), the only difference is
/// line count.
class TextFieldRenderer extends StatelessWidget {
  const TextFieldRenderer({
    super.key,
    required this.spec,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final FormFieldSpec spec;
  final TextValue value;
  final ValidationResult? error;
  final ValueChanged<FieldValue> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, placeholder, isRequired, sizeHint, maxLines) = switch (spec) {
      TextFieldSpec s => (
        s.label,
        s.placeholder,
        s.validation.required,
        s.sizeHint,
        1,
      ),
      MultilineFieldSpec s => (
        s.label,
        s.placeholder,
        s.validation.required,
        s.sizeHint,
        4,
      ),
      _ => throw StateError(
        'TextFieldRenderer given unsupported spec ${spec.runtimeType}',
      ),
    };

    return DsTextField(
      label: label,
      onChanged: (text) => onChanged(TextValue(text)),
      initialValue: value.text,
      hintText: placeholder,
      errorText: resolveValidationMessage(l10n, error),
      isRequired: isRequired,
      maxLines: maxLines,
      size: sizeHint.toDs,
    );
  }
}
