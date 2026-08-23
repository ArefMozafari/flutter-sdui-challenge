import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_size_hint.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_validation.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/select_option.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/dto/style/server_style_resolver.dart';

/// Parses one field of the server's `fields` array into a [FormFieldSpec].
///
/// Accepts two wire shapes:
/// - **New format** — a flat `type` (`text`/`number`/`multiline`/`select`/
///   `file`) and a dedicated `validation` object. This is what the mock
///   datasource actually serves (`assets/mock/car_listing_form.json`).
/// - **Legacy format** — the shape the README's sample response used:
///   `type: "input"` with the real type nested at `props.type`, `textarea`
///   for multiline, and no `validation` object at all (rules, where they
///   exist, live scattered across `props`). Kept alive only so
///   `assets/mock/legacy_form.json` — the sample verbatim — still parses;
///   nothing in the running app serves this shape.
///
/// The two are told apart by one signal: presence of a `validation` key.
/// New-format payloads always have one; legacy payloads never do. This is
/// more robust than sniffing `type`, since `type: "select"` and
/// `type: "file"` happen to be spelled the same in both formats.
///
/// The **compatibility shim is structural only**: it flattens the type
/// discriminator and promotes whatever validation-relevant data legacy
/// `props` actually carries (`min`/`max`/`accept`/`maxSize`/`multiple`).
/// It does **not** attempt to reconstruct legacy `style.borderRadius`,
/// `style.margin`, or `props.color` into anything — those are pure
/// presentation noise with no Domain concept to map onto, and are simply
/// dropped. A legacy field renders with the design system's defaults.
class FormFieldSpecDto {
  const FormFieldSpecDto._();

  static final _styleResolver = const ServerStyleResolver();

  static final Map<
    String,
    FormFieldSpec Function(_NormalizedField, FieldSizeHint)
  >
  _parsers = {
    'text': _parseText,
    'number': _parseNumber,
    'multiline': _parseMultiline,
    'select': _parseSelect,
    'file': _parseFile,
  };

  static FormFieldSpec fromJson(Map<String, dynamic> json) {
    final sizeHint = _styleResolver.resolveSizeHint(
      style: json['style'] as Map<String, dynamic>?,
      props: json['props'] as Map<String, dynamic>?,
    );
    final normalized = json.containsKey('validation')
        ? _NormalizedField.fromNewFormat(json)
        : _NormalizedField.fromLegacyFormat(json);

    final parser = _parsers[normalized.type];
    if (parser == null) {
      return UnsupportedFieldSpec(
        name: normalized.name,
        label: normalized.label,
        rawType: normalized.type,
      );
    }
    return parser(normalized, sizeHint);
  }
}

FormFieldSpec _parseText(_NormalizedField f, FieldSizeHint hint) =>
    TextFieldSpec(
      name: f.name,
      label: f.label,
      placeholder: f.placeholder,
      validation: f.validation,
      sizeHint: hint,
    );

FormFieldSpec _parseNumber(_NormalizedField f, FieldSizeHint hint) =>
    NumberFieldSpec(
      name: f.name,
      label: f.label,
      placeholder: f.placeholder,
      validation: f.validation,
      sizeHint: hint,
    );

FormFieldSpec _parseMultiline(_NormalizedField f, FieldSizeHint hint) =>
    MultilineFieldSpec(
      name: f.name,
      label: f.label,
      placeholder: f.placeholder,
      validation: f.validation,
      sizeHint: hint,
    );

FormFieldSpec _parseSelect(_NormalizedField f, FieldSizeHint hint) =>
    SelectFieldSpec(
      name: f.name,
      label: f.label,
      options: f.options,
      validation: f.validation,
      sizeHint: hint,
    );

FormFieldSpec _parseFile(_NormalizedField f, FieldSizeHint hint) =>
    FileFieldSpec(
      name: f.name,
      label: f.label,
      validation: f.validation,
      sizeHint: hint,
    );

/// The two wire shapes reduced to one shape, before type-specific parsing.
class _NormalizedField {
  const _NormalizedField({
    required this.type,
    required this.name,
    required this.label,
    required this.validation,
    this.placeholder,
    this.options = const [],
  });

  final String type;
  final String name;
  final String label;
  final String? placeholder;
  final List<SelectOption> options;
  final FieldValidation validation;

  factory _NormalizedField.fromNewFormat(Map<String, dynamic> json) {
    return _NormalizedField(
      type: json['type'] as String,
      name: json['name'] as String,
      label: json['label'] as String,
      placeholder: json['placeholder'] as String?,
      options: _parseOptions(json['options']),
      validation: _parseValidation(json['validation'] as Map<String, dynamic>?),
    );
  }

  factory _NormalizedField.fromLegacyFormat(Map<String, dynamic> json) {
    final props = json['props'] as Map<String, dynamic>? ?? const {};
    final legacyType = json['type'] as String;
    final type = switch (legacyType) {
      'input' => (props['type'] as String?) == 'number' ? 'number' : 'text',
      'textarea' => 'multiline',
      _ => legacyType, // 'select' / 'file' already match the new names
    };

    return _NormalizedField(
      type: type,
      name: json['name'] as String,
      label: json['label'] as String,
      placeholder: props['placeholder'] as String?,
      options: _parseOptions(props['options']),
      validation: _validationFromLegacyProps(type, props),
    );
  }
}

List<SelectOption> _parseOptions(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .cast<Map<String, dynamic>>()
      .map(
        (o) => SelectOption(
          label: o['label'] as String,
          value: o['value'].toString(),
        ),
      )
      .toList();
}

FieldValidation _parseValidation(Map<String, dynamic>? json) {
  if (json == null) return FieldValidation.none;
  return FieldValidation(
    required: json['required'] as bool? ?? false,
    minLength: json['minLength'] as int?,
    maxLength: json['maxLength'] as int?,
    min: json['min'] as num?,
    max: json['max'] as num?,
    accept: (json['accept'] as List?)?.cast<String>(),
    maxSizeBytes: json['maxSizeBytes'] as int?,
    maxFiles: json['maxFiles'] as int?,
  );
}

/// Legacy `props` never carried a `required` flag and never distinguished
/// `minLength`/`maxLength` — only what's demonstrably present is promoted.
FieldValidation _validationFromLegacyProps(
  String type,
  Map<String, dynamic> props,
) {
  if (type == 'number') {
    return FieldValidation(
      min: _parseNum(props['min']),
      max: _parseNum(props['max']),
    );
  }
  if (type == 'file') {
    final accept = props['accept'] as String?;
    return FieldValidation(
      accept: accept == null ? null : [accept],
      maxSizeBytes: _parseByteSize(props['maxSize']),
      // `multiple: false` (or absent) means the field only ever held one
      // file to begin with.
      maxFiles: props['multiple'] == true ? null : 1,
    );
  }
  return FieldValidation.none;
}

num? _parseNum(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

/// Parses a legacy human size string like `"5MB"` into bytes.
int? _parseByteSize(Object? value) {
  if (value is! String) return null;
  final match = RegExp(
    r'^(\d+(?:\.\d+)?)\s*(KB|MB|GB)$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;

  final amount = double.parse(match.group(1)!);
  final unit = match.group(2)!.toUpperCase();
  final multiplier = switch (unit) {
    'KB' => 1024,
    'MB' => 1024 * 1024,
    'GB' => 1024 * 1024 * 1024,
    _ => 1,
  };
  return (amount * multiplier).round();
}
