import 'package:flutter/widgets.dart';

import '../../domain/models/field_value.dart';
import '../../domain/models/form_field_spec.dart';
import '../../domain/validation/validation_result.dart';
import 'file_field_renderer.dart';
import 'number_field_renderer.dart';
import 'select_field_renderer.dart';
import 'text_field_renderer.dart';
import 'unsupported_field_renderer.dart';

typedef _Builder =
    Widget Function(
      FormFieldSpec spec,
      FieldValue value,
      ValidationResult? error,
      ValueChanged<FieldValue> onChanged,
    );

/// Maps a [FormFieldSpec] runtime type to the widget that renders it — a
/// runtime `Map`, not a `switch`, and that's deliberate (decision #3 in the
/// plan doc): every other sealed hierarchy in this codebase gets
/// compile-time exhaustiveness, but rendering is the one place that's
/// worth opting out of it. A field type this build doesn't have a renderer
/// for degrades to [UnsupportedFieldRenderer] instead of failing to
/// compile or crashing at runtime — see [UnsupportedFieldSpec].
class FieldWidgetRegistry {
  const FieldWidgetRegistry._();

  static final Map<Type, _Builder> _builders = {
    TextFieldSpec: (spec, value, error, onChanged) => TextFieldRenderer(
      spec: spec,
      value: value as TextValue,
      error: error,
      onChanged: onChanged,
    ),
    MultilineFieldSpec: (spec, value, error, onChanged) => TextFieldRenderer(
      spec: spec,
      value: value as TextValue,
      error: error,
      onChanged: onChanged,
    ),
    NumberFieldSpec: (spec, value, error, onChanged) => NumberFieldRenderer(
      spec: spec as NumberFieldSpec,
      value: value as NumberValue,
      error: error,
      onChanged: onChanged,
    ),
    SelectFieldSpec: (spec, value, error, onChanged) => SelectFieldRenderer(
      spec: spec as SelectFieldSpec,
      value: value as SelectValue,
      error: error,
      onChanged: onChanged,
    ),
    FileFieldSpec: (spec, value, error, onChanged) => FileFieldRenderer(
      spec: spec as FileFieldSpec,
      value: value as FileValue,
      error: error,
      onChanged: onChanged,
    ),
  };

  static Widget build(
    FormFieldSpec spec,
    FieldValue value,
    ValidationResult? error,
    ValueChanged<FieldValue> onChanged,
  ) {
    final builder = _builders[spec.runtimeType];
    if (builder != null) return builder(spec, value, error, onChanged);
    return UnsupportedFieldRenderer(spec: spec as UnsupportedFieldSpec);
  }
}
