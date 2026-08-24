import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_size_hint.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_validation.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/select_option.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/field_validator.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('text field', () {
    final spec = TextFieldSpec(
      name: 'brand',
      label: 'Brand',
      sizeHint: FieldSizeHint.large,
      validation: const FieldValidation(
        required: true,
        minLength: 2,
        maxLength: 5,
      ),
    );

    test('empty required text is invalid', () {
      final result = validateField(spec, const TextValue(''));
      expect(result, isA<InvalidResult>());
      expect((result as InvalidResult).messageKey, 'validationRequired');
    });

    test('below minLength is invalid', () {
      final result = validateField(spec, const TextValue('a'));
      expect((result as InvalidResult).messageKey, 'validationMinLength');
      expect(result.args, {'min': 2});
    });

    test('above maxLength is invalid', () {
      final result = validateField(spec, const TextValue('abcdef'));
      expect((result as InvalidResult).messageKey, 'validationMaxLength');
      expect(result.args, {'max': 5});
    });

    test('within bounds is valid', () {
      expect(validateField(spec, const TextValue('abc')).isValid, isTrue);
    });

    test('optional empty text is valid', () {
      final optional = TextFieldSpec(
        name: 'color',
        label: 'Color',
        sizeHint: FieldSizeHint.medium,
        validation: FieldValidation.none,
      );
      expect(validateField(optional, const TextValue('')).isValid, isTrue);
    });
  });

  group('number field', () {
    final spec = NumberFieldSpec(
      name: 'year',
      label: 'Year',
      sizeHint: FieldSizeHint.medium,
      validation: const FieldValidation(min: 1900, max: 2024),
    );

    test('below min is invalid', () {
      final result = validateField(spec, const NumberValue(1899));
      expect((result as InvalidResult).messageKey, 'validationMin');
    });

    test('above max is invalid', () {
      final result = validateField(spec, const NumberValue(2025));
      expect((result as InvalidResult).messageKey, 'validationMax');
    });

    test('in range is valid', () {
      expect(validateField(spec, const NumberValue(2020)).isValid, isTrue);
    });

    test('null number on optional field is valid', () {
      expect(validateField(spec, const NumberValue(null)).isValid, isTrue);
    });

    test('unparsable text on an optional field is invalid, not dropped', () {
      // The silent case: this used to pass validation and then vanish from
      // the payload, so the user got no error and no submitted value.
      final result = validateField(spec, const NumberValue(null, text: '12a'));
      expect((result as InvalidResult).messageKey, 'validationInvalidNumber');
    });

    test('unparsable text reports invalid rather than required', () {
      final requiredSpec = NumberFieldSpec(
        name: 'year',
        label: 'Year',
        sizeHint: FieldSizeHint.medium,
        validation: const FieldValidation(required: true),
      );

      final result = validateField(
        requiredSpec,
        const NumberValue(null, text: '12a'),
      );

      // "required" over a field visibly containing 12a is simply untrue.
      expect((result as InvalidResult).messageKey, 'validationInvalidNumber');
    });

    test('a genuinely empty required field still reports required', () {
      final requiredSpec = NumberFieldSpec(
        name: 'year',
        label: 'Year',
        sizeHint: FieldSizeHint.medium,
        validation: const FieldValidation(required: true),
      );

      final result = validateField(requiredSpec, const NumberValue(null));
      expect((result as InvalidResult).messageKey, 'validationRequired');
    });

    test('whitespace alone counts as empty, not as unparsable', () {
      expect(
        validateField(spec, const NumberValue(null, text: '   ')).isValid,
        isTrue,
      );
    });

    test('text that parses is validated on the number, not the text', () {
      final result = validateField(spec, const NumberValue(1899, text: '1899'));
      expect((result as InvalidResult).messageKey, 'validationMin');
    });
  });

  group('select field', () {
    final spec = SelectFieldSpec(
      name: 'fuel_type',
      label: 'Fuel',
      sizeHint: FieldSizeHint.medium,
      options: const [SelectOption(label: 'Gas', value: 'gas')],
      validation: const FieldValidation(required: true),
    );

    test('no selection is invalid', () {
      final result = validateField(spec, const SelectValue(null));
      expect((result as InvalidResult).messageKey, 'validationRequired');
    });

    test('a selection is valid', () {
      expect(validateField(spec, const SelectValue('gas')).isValid, isTrue);
    });
  });

  group('file field', () {
    final spec = FileFieldSpec(
      name: 'car_images',
      label: 'Images',
      sizeHint: FieldSizeHint.medium,
      validation: const FieldValidation(
        required: true,
        maxFiles: 2,
        maxSizeBytes: 1024,
        accept: ['image/*'],
      ),
    );

    SelectedFile file({int sizeBytes = 100, String mime = 'image/png'}) =>
        SelectedFile(
          name: 'a.png',
          mimeType: mime,
          bytes: List.filled(sizeBytes, 0),
        );

    test('no files is invalid when required', () {
      final result = validateField(spec, const FileValue([]));
      expect((result as InvalidResult).messageKey, 'validationRequired');
    });

    test('too many files is invalid', () {
      final result = validateField(spec, FileValue([file(), file(), file()]));
      expect((result as InvalidResult).messageKey, 'validationTooManyFiles');
    });

    test('oversized file is invalid', () {
      final result = validateField(spec, FileValue([file(sizeBytes: 2048)]));
      expect((result as InvalidResult).messageKey, 'validationFileTooLarge');
    });

    test('unsupported mime type is invalid', () {
      final result = validateField(
        spec,
        FileValue([file(mime: 'application/pdf')]),
      );
      expect(
        (result as InvalidResult).messageKey,
        'validationUnsupportedFileType',
      );
    });

    test('one valid image file is valid', () {
      expect(validateField(spec, FileValue([file()])).isValid, isTrue);
    });
  });

  test('mismatched spec/value pairing throws', () {
    final spec = TextFieldSpec(
      name: 'brand',
      label: 'Brand',
      sizeHint: FieldSizeHint.medium,
      validation: FieldValidation.none,
    );
    expect(() => validateField(spec, const NumberValue(1)), throwsStateError);
  });

  test('validating an unsupported field spec throws', () {
    const spec = UnsupportedFieldSpec(
      name: 'signature',
      label: 'Signature',
      rawType: 'signature',
    );
    expect(() => validateField(spec, const TextValue('')), throwsStateError);
  });
}
