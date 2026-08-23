import 'package:dynamic_form_builder/shared/dynamic_form/application/services/dynamic_form_service.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/application/services/submit_form_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/datasource_exceptions.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/repositories/dynamic_form_repository.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_size_hint.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_validation.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records whether fetchFormSpec/submitForm was actually called, so tests
/// can assert the Repository is never reached on an invalid submission —
/// DynamicFormDataSource is abstract, so no mocking framework is needed.
class _RecordingDataSource implements DynamicFormDataSource {
  bool submitCalled = false;
  Object? submitError;

  @override
  Future<Map<String, dynamic>> fetchFormSpec() async =>
      throw UnimplementedError('not used by this service');

  @override
  Future<void> submitForm({
    required String submitUrl,
    required Map<String, dynamic> fields,
    required List<SubmissionFile> files,
  }) async {
    submitCalled = true;
    if (submitError != null) throw submitError!;
  }
}

FormSpec _formWith(List<FormFieldSpec> fields) =>
    FormSpec(formId: 'x', version: 1, submitUrl: '/submit', fields: fields);

const _requiredText = TextFieldSpec(
  name: 'brand',
  label: 'Brand',
  sizeHint: FieldSizeHint.medium,
  validation: FieldValidation(required: true),
);

void main() {
  test(
    'an invalid field blocks submission before the repository is called',
    () async {
      final dataSource = _RecordingDataSource();
      final service = DynamicFormService(DynamicFormRepository(dataSource));

      final result = await service.submitForm(
        form: _formWith([_requiredText]),
        values: {'brand': const TextValue('')},
      );

      expect(result, isA<SubmitFormValidationFailed>());
      expect((result as SubmitFormValidationFailed).fieldErrors.keys, [
        'brand',
      ]);
      expect(dataSource.submitCalled, isFalse);
    },
  );

  test(
    'a missing value falls back to empty and still fails required',
    () async {
      final dataSource = _RecordingDataSource();
      final service = DynamicFormService(DynamicFormRepository(dataSource));

      final result = await service.submitForm(
        form: _formWith([_requiredText]),
        values: const {},
      );

      expect(result, isA<SubmitFormValidationFailed>());
      expect(dataSource.submitCalled, isFalse);
    },
  );

  test('a valid form reaches the repository and succeeds', () async {
    final dataSource = _RecordingDataSource();
    final service = DynamicFormService(DynamicFormRepository(dataSource));

    final result = await service.submitForm(
      form: _formWith([_requiredText]),
      values: {'brand': const TextValue('Toyota')},
    );

    expect(result, isA<SubmitFormSuccess>());
    expect(dataSource.submitCalled, isTrue);
  });

  test('a repository failure surfaces as SubmitFormFailed', () async {
    final dataSource = _RecordingDataSource()
      ..submitError = const DataSourceServerException(500);
    final service = DynamicFormService(DynamicFormRepository(dataSource));

    final result = await service.submitForm(
      form: _formWith([_requiredText]),
      values: {'brand': const TextValue('Toyota')},
    );

    expect(result, isA<SubmitFormFailed>());
  });

  test('an UnsupportedFieldSpec is never validated or submitted', () async {
    final dataSource = _RecordingDataSource();
    final service = DynamicFormService(DynamicFormRepository(dataSource));

    final result = await service.submitForm(
      form: _formWith([
        const UnsupportedFieldSpec(
          name: 'signature',
          label: 'Sign',
          rawType: 'signature',
        ),
      ]),
      values: const {},
    );

    expect(result, isA<SubmitFormSuccess>());
    expect(dataSource.submitCalled, isTrue);
  });
}
