/// What the user has entered into one field, as a Dart 3 sealed hierarchy
/// mirroring [FormFieldSpec]. Sealed for the same reason as the spec: the
/// validator pattern-matches `(FormFieldSpec, FieldValue)` pairs, and the
/// compiler flags any pairing that isn't handled.
sealed class FieldValue {
  const FieldValue();
}

final class TextValue extends FieldValue {
  const TextValue(this.text);
  final String text;
}

/// `number` is null when the field is empty (not yet typed, or cleared) —
/// distinct from `0`, which is a legitimate value.
final class NumberValue extends FieldValue {
  const NumberValue(this.number);
  final num? number;
}

/// `value` is null when nothing is selected yet.
final class SelectValue extends FieldValue {
  const SelectValue(this.value);
  final String? value;
}

final class FileValue extends FieldValue {
  const FileValue(this.files);
  final List<SelectedFileMeta> files;
}

/// Metadata for a file the user picked, enough to validate against
/// [FieldValidation] (size, count, accepted MIME type) without Domain ever
/// touching the actual bytes or a platform file-picker type.
class SelectedFileMeta {
  const SelectedFileMeta({
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
  });

  final String name;
  final int sizeBytes;
  final String mimeType;
}
