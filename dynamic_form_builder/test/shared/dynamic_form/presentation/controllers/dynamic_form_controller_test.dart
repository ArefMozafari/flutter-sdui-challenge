import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/datasource_exceptions.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/repositories/dynamic_form_repository.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/controllers/dynamic_form_controller.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/states/dynamic_form_view_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _formJson = {
  'formId': 'x',
  'version': 1,
  'submitUrl': '/submit',
  'fields': [
    {
      'type': 'text',
      'name': 'brand',
      'label': 'Brand',
      'validation': {'required': true, 'minLength': 2},
    },
  ],
};

/// Configurable fake — no mocking framework needed, DynamicFormDataSource
/// is abstract.
class _FakeDataSource implements DynamicFormDataSource {
  Object? fetchError;
  bool submitCalled = false;

  @override
  Future<Map<String, dynamic>> fetchFormSpec() async {
    if (fetchError != null) throw fetchError!;
    return _formJson;
  }

  @override
  Future<void> submitForm({
    required String submitUrl,
    required Map<String, dynamic> fields,
    required List<SubmissionFile> files,
  }) async {
    submitCalled = true;
  }
}

ProviderContainer _containerWith(_FakeDataSource dataSource) {
  final container = ProviderContainer(
    overrides: [
      dynamicFormRepositoryProvider.overrideWithValue(
        DynamicFormRepository(dataSource),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('loads the form and seeds an empty value per field', () async {
    final container = _containerWith(_FakeDataSource());
    final notifier = container.read(dynamicFormControllerProvider.notifier);
    await notifier.retryLoad();

    final state = container.read(dynamicFormControllerProvider);
    expect(state, isA<DynamicFormLoaded>());
    final loaded = state as DynamicFormLoaded;
    expect(loaded.spec.formId, 'x');
    expect(loaded.values['brand'], isA<TextValue>());
  });

  test('a fetch failure surfaces as DynamicFormLoadError', () async {
    final dataSource = _FakeDataSource()
      ..fetchError = const DataSourceNetworkException();
    final container = _containerWith(dataSource);
    final notifier = container.read(dynamicFormControllerProvider.notifier);
    await notifier.retryLoad();

    expect(
      container.read(dynamicFormControllerProvider),
      isA<DynamicFormLoadError>(),
    );
  });

  test('updateValue updates one field and clears its own error', () async {
    final container = _containerWith(_FakeDataSource());
    final notifier = container.read(dynamicFormControllerProvider.notifier);
    await notifier.retryLoad();

    await notifier.submit(); // 'brand' is required and empty -> fieldErrors set
    expect(
      (container.read(dynamicFormControllerProvider) as DynamicFormLoaded)
          .fieldErrors,
      contains('brand'),
    );

    notifier.updateValue('brand', const TextValue('Toyota'));
    final loaded =
        container.read(dynamicFormControllerProvider) as DynamicFormLoaded;
    expect((loaded.values['brand'] as TextValue).text, 'Toyota');
    expect(loaded.fieldErrors, isNot(contains('brand')));
  });

  test('submit with an invalid field never reaches the datasource', () async {
    final dataSource = _FakeDataSource();
    final container = _containerWith(dataSource);
    final notifier = container.read(dynamicFormControllerProvider.notifier);
    await notifier.retryLoad();

    await notifier.submit();

    expect(dataSource.submitCalled, isFalse);
    final loaded =
        container.read(dynamicFormControllerProvider) as DynamicFormLoaded;
    expect(loaded.fieldErrors, contains('brand'));
    expect(loaded.isSubmitting, isFalse);
  });

  test('submit with valid data reaches the datasource and succeeds', () async {
    final dataSource = _FakeDataSource();
    final container = _containerWith(dataSource);
    final notifier = container.read(dynamicFormControllerProvider.notifier);
    await notifier.retryLoad();
    notifier.updateValue('brand', const TextValue('Toyota'));

    await notifier.submit();

    expect(dataSource.submitCalled, isTrue);
    final loaded =
        container.read(dynamicFormControllerProvider) as DynamicFormLoaded;
    expect(loaded.submitSucceeded, isTrue);
    expect(loaded.isSubmitting, isFalse);
  });

  test('retryLoad resets to loading before reloading', () async {
    final container = _containerWith(_FakeDataSource());
    final notifier = container.read(dynamicFormControllerProvider.notifier);
    await notifier.retryLoad();
    expect(
      container.read(dynamicFormControllerProvider),
      isA<DynamicFormLoaded>(),
    );

    final future = notifier.retryLoad();
    expect(
      container.read(dynamicFormControllerProvider),
      isA<DynamicFormLoading>(),
    );
    await future;
    expect(
      container.read(dynamicFormControllerProvider),
      isA<DynamicFormLoaded>(),
    );
  });
}
