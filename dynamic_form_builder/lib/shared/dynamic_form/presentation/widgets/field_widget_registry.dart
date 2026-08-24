import 'package:flutter/widgets.dart';

import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/file_field_renderer.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/number_field_renderer.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/select_field_renderer.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/text_field_renderer.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/unsupported_field_renderer.dart';

typedef _Builder =
    Widget Function(
      FormFieldSpec spec,
      FieldValue value,
      ValidationResult? error,
      ValueChanged<FieldValue> onChanged,
      bool enabled,
    );

/// Maps a [FormFieldSpec] runtime type to the widget that renders it — a
/// runtime `Map`, not a `switch`, and that's deliberate (decision #3 in the
/// plan doc): every other sealed hierarchy in this codebase gets
/// compile-time exhaustiveness, but rendering is the one place that's
/// worth opting out of it. A field type this build doesn't have a renderer
/// for degrades to [UnsupportedFieldRenderer] instead of failing to
/// compile or crashing at runtime — see [UnsupportedFieldSpec].
///
/// Worth being precise about what that buys, because the fallback used to
/// promise more than it delivered. The graceful path for an unknown *wire*
/// type comes from Domain modelling it as an [UnsupportedFieldSpec], not
/// from this map — a `switch` would handle that case identically. What the
/// map actually trades away is the compile error for a *known* subtype with
/// no entry here, and that case now renders
/// [UnsupportedFieldRenderer.forUnrendered] rather than throwing. It still
/// isn't free: see that constructor for what a missing entry costs.
class FieldWidgetRegistry {
  const FieldWidgetRegistry._();

  static final Map<Type, _Builder> _builders = {
    TextFieldSpec: (spec, value, error, onChanged, enabled) =>
        TextFieldRenderer(
          spec: spec,
          value: value as TextValue,
          error: error,
          onChanged: onChanged,
          enabled: enabled,
        ),
    MultilineFieldSpec: (spec, value, error, onChanged, enabled) =>
        TextFieldRenderer(
          spec: spec,
          value: value as TextValue,
          error: error,
          onChanged: onChanged,
          enabled: enabled,
        ),
    NumberFieldSpec: (spec, value, error, onChanged, enabled) =>
        NumberFieldRenderer(
          spec: spec as NumberFieldSpec,
          value: value as NumberValue,
          error: error,
          onChanged: onChanged,
          enabled: enabled,
        ),
    SelectFieldSpec: (spec, value, error, onChanged, enabled) =>
        SelectFieldRenderer(
          spec: spec as SelectFieldSpec,
          value: value as SelectValue,
          error: error,
          onChanged: onChanged,
          enabled: enabled,
        ),
    FileFieldSpec: (spec, value, error, onChanged, enabled) =>
        FileFieldRenderer(
          spec: spec as FileFieldSpec,
          value: value as FileValue,
          error: error,
          onChanged: onChanged,
          enabled: enabled,
        ),
  };

  /// Named rather than positional: five arguments in a fixed order is the
  /// point where a call site stops being readable and a transposition stops
  /// being caught by the type checker.
  static Widget build({
    required FormFieldSpec spec,
    required FieldValue value,
    required ValidationResult? error,
    required ValueChanged<FieldValue> onChanged,
    required bool enabled,
  }) {
    final builder = _builders[spec.runtimeType];
    if (builder != null) {
      return builder(spec, value, error, onChanged, enabled);
    }
    // Branch rather than cast. `spec as UnsupportedFieldSpec` held only for
    // the wire-unknown case; for any *known* subtype missing from the map
    // above it threw a TypeError on screen — the runtime crash this
    // registry's own design is meant to rule out.
    return switch (spec) {
      UnsupportedFieldSpec() => UnsupportedFieldRenderer(spec: spec),
      _ => UnsupportedFieldRenderer.forUnrendered(spec),
    };
  }
}
