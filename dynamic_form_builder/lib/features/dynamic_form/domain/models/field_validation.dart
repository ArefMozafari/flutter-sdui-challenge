/// Declarative validation rules attached to a [FormFieldSpec].
///
/// Kept as one plain value object rather than a list of rule objects —
/// every rule here is a simple bound check with no shared behavior to
/// polymorph over, so a class hierarchy would just add indirection.
/// [FieldValidator] is what turns these bounds into a [ValidationResult].
class FieldValidation {
  const FieldValidation({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.accept,
    this.maxSizeBytes,
    this.maxFiles,
  });

  /// No rules at all — every value passes.
  static const none = FieldValidation();

  final bool required;

  /// Text/multiline: minimum character count.
  final int? minLength;

  /// Text/multiline: maximum character count.
  final int? maxLength;

  /// Number: minimum numeric value (inclusive).
  final num? min;

  /// Number: maximum numeric value (inclusive).
  final num? max;

  /// File: accepted MIME patterns, e.g. `image/*`.
  final List<String>? accept;

  /// File: maximum size per file, in bytes.
  final int? maxSizeBytes;

  /// File: maximum number of files.
  final int? maxFiles;
}
