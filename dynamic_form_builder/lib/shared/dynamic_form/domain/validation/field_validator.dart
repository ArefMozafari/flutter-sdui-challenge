import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_validation.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';

/// Validates one field's current [FieldValue] against its [FormFieldSpec].
///
/// The outer `switch` is over [spec] alone, so it's exhaustive over all six
/// [FormFieldSpec] subtypes at compile time — add a seventh and this fails
/// to build until it's handled, the same guarantee the widget registry
/// deliberately opts out of (see `FieldWidgetRegistry`). Each case then
/// asserts [value] is the matching [FieldValue] subtype via `_expect*`:
/// that pairing is an invariant kept by whoever constructs the initial
/// [FieldValue] for a field (the Presentation controller, in Branch 3) —
/// every [TextFieldSpec] always starts life paired with a [TextValue],
/// never a [NumberValue]. A mismatch is a programming error, not a user
/// input error, so it throws rather than degrading to a silent "valid".
ValidationResult validateField(FormFieldSpec spec, FieldValue value) {
  return switch (spec) {
    TextFieldSpec() => _validateText(spec.validation, _expectText(spec, value)),
    MultilineFieldSpec() => _validateText(
      spec.validation,
      _expectText(spec, value),
    ),
    NumberFieldSpec() => _validateNumber(
      spec.validation,
      _expectNumber(spec, value),
    ),
    SelectFieldSpec() => _validateSelect(
      spec.validation,
      _expectSelect(spec, value),
    ),
    FileFieldSpec() => _validateFiles(
      spec.validation,
      _expectFiles(spec, value),
    ),
    UnsupportedFieldSpec() => throw StateError(
      'UnsupportedFieldSpec "${spec.name}" is never editable and should '
      'never reach the validator',
    ),
  };
}

TextValue _expectText(FormFieldSpec spec, FieldValue value) =>
    value is TextValue ? value : _mismatch(spec, value);

NumberValue _expectNumber(FormFieldSpec spec, FieldValue value) =>
    value is NumberValue ? value : _mismatch(spec, value);

SelectValue _expectSelect(FormFieldSpec spec, FieldValue value) =>
    value is SelectValue ? value : _mismatch(spec, value);

FileValue _expectFiles(FormFieldSpec spec, FieldValue value) =>
    value is FileValue ? value : _mismatch(spec, value);

Never _mismatch(FormFieldSpec spec, FieldValue value) => throw StateError(
  'FieldValue ${value.runtimeType} does not match '
  'FormFieldSpec ${spec.runtimeType} for field "${spec.name}"',
);

ValidationResult _validateText(FieldValidation rules, TextValue value) {
  final text = value.text.trim();

  if (rules.required && text.isEmpty) {
    return const ValidationResult.invalid('validationRequired');
  }
  if (text.isEmpty) {
    return const ValidationResult.valid();
  }
  final minLength = rules.minLength;
  if (minLength != null && text.length < minLength) {
    return ValidationResult.invalid(
      'validationMinLength',
      args: {'min': minLength},
    );
  }
  final maxLength = rules.maxLength;
  if (maxLength != null && text.length > maxLength) {
    return ValidationResult.invalid(
      'validationMaxLength',
      args: {'max': maxLength},
    );
  }
  return const ValidationResult.valid();
}

ValidationResult _validateNumber(FieldValidation rules, NumberValue value) {
  final number = value.number;

  // Before `required`, on purpose. A field showing `12a` is not empty, and
  // answering it with "this field is required" describes something the user
  // can plainly see isn't true. This also catches the optional case, which
  // used to pass validation and then quietly drop the value from the
  // payload — no error, no number submitted, nothing to notice.
  if (value.isUnparsable) {
    return const ValidationResult.invalid('validationInvalidNumber');
  }
  if (rules.required && number == null) {
    return const ValidationResult.invalid('validationRequired');
  }
  if (number == null) {
    return const ValidationResult.valid();
  }
  final min = rules.min;
  if (min != null && number < min) {
    return ValidationResult.invalid('validationMin', args: {'min': min});
  }
  final max = rules.max;
  if (max != null && number > max) {
    return ValidationResult.invalid('validationMax', args: {'max': max});
  }
  return const ValidationResult.valid();
}

ValidationResult _validateSelect(FieldValidation rules, SelectValue value) {
  if (rules.required && (value.value == null || value.value!.isEmpty)) {
    return const ValidationResult.invalid('validationRequired');
  }
  return const ValidationResult.valid();
}

ValidationResult _validateFiles(FieldValidation rules, FileValue value) {
  final files = value.files;

  if (rules.required && files.isEmpty) {
    return const ValidationResult.invalid('validationRequired');
  }

  final maxFiles = rules.maxFiles;
  if (maxFiles != null && files.length > maxFiles) {
    return ValidationResult.invalid(
      'validationTooManyFiles',
      args: {'max': maxFiles},
    );
  }

  final maxSizeBytes = rules.maxSizeBytes;
  if (maxSizeBytes != null) {
    final tooLarge = files.any((f) => f.sizeBytes > maxSizeBytes);
    if (tooLarge) {
      return ValidationResult.invalid(
        'validationFileTooLarge',
        args: {'maxSize': _formatBytes(maxSizeBytes)},
      );
    }
  }

  final accept = rules.accept;
  if (accept != null && accept.isNotEmpty) {
    final unsupported = files.any((f) => !_matchesAny(f.mimeType, accept));
    if (unsupported) {
      return const ValidationResult.invalid('validationUnsupportedFileType');
    }
  }

  return const ValidationResult.valid();
}

/// Matches `image/png` against a pattern list like `['image/*']`.
bool _matchesAny(String mimeType, List<String> patterns) {
  return patterns.any((pattern) {
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return mimeType.startsWith(prefix);
    }
    return mimeType == pattern;
  });
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)}KB';
  }
  return '${bytes}B';
}
