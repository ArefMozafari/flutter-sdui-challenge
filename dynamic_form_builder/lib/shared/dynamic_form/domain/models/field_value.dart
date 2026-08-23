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
  final List<SelectedFile> files;
}

/// A file the user picked. Carries the actual bytes, not just metadata —
/// `List<int>` is plain Dart data, so holding it doesn't cost Domain its
/// purity (no `BuildContext`, no platform file-picker type, still zero
/// Flutter imports). It has to: Application's `submitForm` needs real bytes
/// to build a Data-layer `SubmissionFile`, and since Presentation stays
/// Domain-shaped for that call (see the layer-skip rule in the plan doc),
/// there's nowhere else for them to come from. [sizeBytes] is derived from
/// [bytes] rather than stored separately — a second stored length would
/// just be a value that could drift from the bytes it's supposedly
/// describing.
class SelectedFile {
  const SelectedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final List<int> bytes;

  int get sizeBytes => bytes.length;
}
