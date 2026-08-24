import 'dart:async';

import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/datasource_exceptions.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/repositories/dynamic_form_repository.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/controllers/dynamic_form_controller.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/states/dynamic_form_view_state.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/states/submit_status.dart';
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
  int submitCount = 0;
  Map<String, dynamic>? submittedFields;

  /// When set, `submitForm` parks on it instead of returning — lets a test
  /// hold a request in flight and act on the controller while it runs.
  Completer<void>? submitGate;

  bool get submitCalled => submitCount > 0;

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
    submitCount++;
    submittedFields = fields;
    if (submitGate != null) await submitGate!.future;
  }
}

DynamicFormLoaded _loaded(ProviderContainer container) =>
    container.read(dynamicFormControllerProvider) as DynamicFormLoaded;

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
    expect(loaded.status, isA<SubmitRejected>());
    expect(loaded.fieldErrors, contains('brand'));
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
    expect(loaded.status, isA<SubmitSucceeded>());
  });

  test(
    'an edit mid-submit neither cancels it nor lets a second one start',
    () async {
      final dataSource = _FakeDataSource()..submitGate = Completer<void>();
      final container = _containerWith(dataSource);
      final notifier = container.read(dynamicFormControllerProvider.notifier);
      await notifier.retryLoad();
      notifier.updateValue('brand', const TextValue('Toyota'));

      final inFlight = notifier.submit();
      expect(_loaded(container).status, isA<SubmitInProgress>());

      // The edit that used to reset isSubmitting to false. The status has to
      // survive it, and the value has to stay the one being submitted.
      notifier.updateValue('brand', const TextValue('Honda'));
      expect(_loaded(container).status, isA<SubmitInProgress>());
      expect((_loaded(container).values['brand'] as TextValue).text, 'Toyota');

      // ...which is what used to let this second call through.
      await notifier.submit();
      expect(dataSource.submitCount, 1);

      dataSource.submitGate!.complete();
      await inFlight;

      expect(_loaded(container).status, isA<SubmitSucceeded>());
      expect(dataSource.submittedFields!['brand'], 'Toyota');
    },
  );

  test(
    'a submit result never clobbers a form reloaded while it was in flight',
    () async {
      final dataSource = _FakeDataSource()..submitGate = Completer<void>();
      final container = _containerWith(dataSource);
      final notifier = container.read(dynamicFormControllerProvider.notifier);
      await notifier.retryLoad();
      notifier.updateValue('brand', const TextValue('Toyota'));

      final inFlight = notifier.submit();
      await notifier.retryLoad(); // replaces the form underneath the request

      dataSource.submitGate!.complete();
      await inFlight;

      // Still the freshly loaded form, not the submitted one's success banner.
      final reloaded = _loaded(container);
      expect(reloaded.status, isA<SubmitIdle>());
      expect((reloaded.values['brand'] as TextValue).text, isEmpty);
    },
  );

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
