import 'dart:convert';
import 'dart:io';

import 'package:dynamic_form_builder/shared/dynamic_form/data/dto/form_spec_dto.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadFixture(String name) {
  final raw = File('assets/mock/$name').readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  group('car_listing_form.json (new format)', () {
    late Map<String, dynamic> json;

    setUpAll(() => json = _loadFixture('car_listing_form.json'));

    test('parses formId, version and submitUrl', () {
      final spec = FormSpecDto.fromJson(json);
      expect(spec.formId, 'car_listing');
      expect(spec.version, 1);
      expect(spec.submitUrl, '/api/forms/car_listing/submit');
    });

    test('parses every field as its matching subtype', () {
      final fields = FormSpecDto.fromJson(json).fields;
      expect(fields, hasLength(8));
      expect(fields[0], isA<TextFieldSpec>()); // brand
      expect(fields[2], isA<NumberFieldSpec>()); // year
      expect(fields[3], isA<SelectFieldSpec>()); // fuel_type
      expect(fields[6], isA<MultilineFieldSpec>()); // technical_condition
      expect(fields[7], isA<FileFieldSpec>()); // car_images
    });

    test('select field carries its options', () {
      final fuelType = FormSpecDto.fromJson(json).fields[3] as SelectFieldSpec;
      expect(fuelType.options, hasLength(4));
      expect(fuelType.options.first.value, 'gasoline');
    });

    test('file field validation carries accept/maxSizeBytes/maxFiles', () {
      final images = FormSpecDto.fromJson(json).fields[7] as FileFieldSpec;
      expect(images.validation.accept, ['image/*']);
      expect(images.validation.maxSizeBytes, 5242880);
      expect(images.validation.maxFiles, 10);
    });

    test('style.size resolves to the matching FieldSizeHint', () {
      final brand = FormSpecDto.fromJson(json).fields[0] as TextFieldSpec;
      expect(brand.sizeHint.name, 'large');
    });
  });

  group('legacy_form.json (compatibility shim)', () {
    late Map<String, dynamic> json;

    setUpAll(() => json = _loadFixture('legacy_form.json'));

    test('missing formId/version/submitUrl fall back to defaults', () {
      final spec = FormSpecDto.fromJson(json);
      expect(spec.formId, 'legacy_form');
      expect(spec.version, 1);
      expect(spec.submitUrl, '');
    });

    test('type:input + props.type flattens to text/number', () {
      final fields = FormSpecDto.fromJson(json).fields;
      expect(fields[0], isA<TextFieldSpec>()); // brand
      expect(fields[2], isA<NumberFieldSpec>()); // year
    });

    test('type:textarea flattens to multiline', () {
      expect(FormSpecDto.fromJson(json).fields[6], isA<MultilineFieldSpec>());
    });

    test('legacy number props.min/max promote to validation', () {
      final year = FormSpecDto.fromJson(json).fields[2] as NumberFieldSpec;
      expect(year.validation.min, 1900);
      expect(year.validation.max, 2024);
    });

    test('legacy file props.accept/maxSize/multiple promote to validation', () {
      final images = FormSpecDto.fromJson(json).fields[7] as FileFieldSpec;
      expect(images.validation.accept, ['image/*']);
      expect(images.validation.maxSizeBytes, 5 * 1024 * 1024);
      expect(images.validation.maxFiles, isNull); // multiple:true -> unbounded
    });

    test('never invents a required flag the legacy payload never sent', () {
      for (final field in FormSpecDto.fromJson(json).fields) {
        expect(field.validation.required, isFalse);
      }
    });
  });

  group('unrecognized field type', () {
    test('falls back to UnsupportedFieldSpec instead of throwing', () {
      final json = {
        'fields': [
          {
            'type': 'signature',
            'name': 'sig',
            'label': 'Sign here',
            'validation': <String, dynamic>{},
          },
        ],
      };
      final field = FormSpecDto.fromJson(json).fields.single;
      expect(field, isA<UnsupportedFieldSpec>());
      expect((field as UnsupportedFieldSpec).rawType, 'signature');
    });
  });

  group('malformed json', () {
    test('a field missing its required name throws', () {
      final json = {
        'fields': [
          {'type': 'text', 'label': 'Brand', 'validation': <String, dynamic>{}},
        ],
      };
      expect(() => FormSpecDto.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
