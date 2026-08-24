import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';

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

/// `number` is null when the field holds no usable number — either it's
/// empty (not yet typed, or cleared), or what's in it doesn't parse.
/// Null is distinct from `0`, which is a legitimate value.
///
/// [text] is what the field is actually showing, and telling those two
/// cases apart is the whole reason it's carried. `DsTextField` owns its
/// controller and is the source of truth for the raw text after first build
/// (deliberately — it's what stops an unrelated rebuild resetting the
/// cursor), so without [text] here, state and screen diverge: typing `12a`
/// left this holding `NumberValue(null)`, indistinguishable from empty,
/// while the field went on displaying `12a`. A required field then reported
/// "this field is required" over visible text, and an optional one dropped
/// the value from the payload with no feedback at all.
final class NumberValue extends FieldValue {
  const NumberValue(this.number, {this.text = ''});

  final num? number;

  /// The raw text this value was parsed from. Empty for a field the user
  /// hasn't typed in, which is what makes "empty" distinguishable from
  /// "unparsable" — see [validateField].
  final String text;

  /// True when the field visibly contains something that isn't a number.
  bool get isUnparsable => number == null && text.trim().isNotEmpty;
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
