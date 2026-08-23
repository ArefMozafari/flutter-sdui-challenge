import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_size_hint.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_validation.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initialFieldValue matches the right FieldValue subtype per spec', () {
    const sizeHint = FieldSizeHint.medium;
    const validation = FieldValidation.none;

    expect(
      initialFieldValue(
        const TextFieldSpec(
          name: 'a',
          label: 'A',
          sizeHint: sizeHint,
          validation: validation,
        ),
      ),
      isA<TextValue>(),
    );
    expect(
      initialFieldValue(
        const MultilineFieldSpec(
          name: 'a',
          label: 'A',
          sizeHint: sizeHint,
          validation: validation,
        ),
      ),
      isA<TextValue>(),
    );
    expect(
      initialFieldValue(
        const NumberFieldSpec(
          name: 'a',
          label: 'A',
          sizeHint: sizeHint,
          validation: validation,
        ),
      ),
      isA<NumberValue>(),
    );
    expect(
      initialFieldValue(
        const SelectFieldSpec(
          name: 'a',
          label: 'A',
          sizeHint: sizeHint,
          validation: validation,
          options: [],
        ),
      ),
      isA<SelectValue>(),
    );
    expect(
      initialFieldValue(
        const FileFieldSpec(
          name: 'a',
          label: 'A',
          sizeHint: sizeHint,
          validation: validation,
        ),
      ),
      isA<FileValue>(),
    );
  });

  test('SelectedFile.sizeBytes is derived from bytes, not stored', () {
    final file = SelectedFile(
      name: 'a.png',
      mimeType: 'image/png',
      bytes: List.filled(42, 0),
    );
    expect(file.sizeBytes, 42);
  });
}
