import 'form_field_spec.dart';

/// What the user has entered into one field, as a Dart 3 sealed hierarchy
/// mirroring [FormFieldSpec]. Sealed for the same reason as the spec: the
/// validator pattern-matches `(FormFieldSpec, FieldValue)` pairs, and the
/// compiler flags any pairing that isn't handled.
sealed class FieldValue {
  const FieldValue();
}

/// The empty [FieldValue] for a freshly-loaded field, before the user has
/// touched it. Two callers need this and neither is the right owner of the
/// spec-to-empty-value pairing on its own: the Presentation controller
/// seeds a `Map<String, FieldValue>` with one of these per field as soon as
/// the form loads, and Application's `submitForm` falls back to one if a
/// field is somehow missing from that map — falling back to an empty value
/// (not skipping the field) so a missing *required* field still fails
/// validation instead of silently passing.
FieldValue initialFieldValue(FormFieldSpec spec) => switch (spec) {
  TextFieldSpec() || MultilineFieldSpec() => const TextValue(''),
  NumberFieldSpec() => const NumberValue(null),
  SelectFieldSpec() => const SelectValue(null),
  FileFieldSpec() => const FileValue([]),
  // Never rendered, never editable, never submitted (see UnsupportedFieldSpec's
  // own doc comment) — this case only exists so the switch above stays
  // exhaustive over all six FormFieldSpec subtypes.
  UnsupportedFieldSpec() => const TextValue(''),
};

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
