import 'dart:async';

import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/datasource_exceptions.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/repositories/dynamic_form_repository.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/dynamic_form_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _formJson = {
  'formId': 'car_listing',
  'version': 1,
  'submitUrl': '/submit',
  'fields': [
    {
      'type': 'text',
      'name': 'brand',
      'label': 'Brand',
      'validation': {'required': true, 'minLength': 2},
    },
    {
      'type': 'select',
      'name': 'fuel_type',
      'label': 'Fuel',
      'options': [
        {'label': 'Gasoline', 'value': 'gasoline'},
        {'label': 'Diesel', 'value': 'diesel'},
      ],
      'validation': {'required': true},
    },
  ],
};

class _FakeDataSource implements DynamicFormDataSource {
  _FakeDataSource({this.fetchError});

  Object? fetchError;
  bool submitCalled = false;
  Map<String, dynamic>? submittedFields;

  /// When set, `submitForm` parks on it instead of returning — lets a test
  /// drive the UI while a request is still in flight.
  Completer<void>? submitGate;

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
    submittedFields = fields;
    if (submitGate != null) await submitGate!.future;
  }
}

Widget _harness(_FakeDataSource dataSource) {
  return ProviderScope(
    overrides: [
      dynamicFormRepositoryProvider.overrideWithValue(
        DynamicFormRepository(dataSource),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: DynamicFormView()),
    ),
  );
}

void main() {
  testWidgets('renders every field label once the form loads', (tester) async {
    await tester.pumpWidget(_harness(_FakeDataSource()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Brand'), findsWidgets);
    expect(find.textContaining('Fuel'), findsWidgets);
  });

  testWidgets(
    'submitting an empty required field shows an inline error and never calls the datasource',
    (tester) async {
      final dataSource = _FakeDataSource();
      await tester.pumpWidget(_harness(dataSource));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(context);

      await tester.tap(find.text(l10n.actionSubmit));
      await tester.pumpAndSettle();

      expect(find.text(l10n.validationRequired), findsWidgets);
      expect(dataSource.submitCalled, isFalse);
    },
  );

  testWidgets('filling every required field and submitting succeeds', (
    tester,
  ) async {
    final dataSource = _FakeDataSource();
    await tester.pumpWidget(_harness(dataSource));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.enterText(find.byType(TextFormField), 'Toyota');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gasoline').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.actionSubmit));
    await tester.pumpAndSettle();

    expect(dataSource.submitCalled, isTrue);
    expect(find.text(l10n.stateSubmitSuccess), findsOneWidget);
  });

  testWidgets('every field is locked while a submit is in flight', (
    tester,
  ) async {
    final dataSource = _FakeDataSource()..submitGate = Completer<void>();
    await tester.pumpWidget(_harness(dataSource));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.enterText(find.byType(TextFormField), 'Toyota');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gasoline').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.actionSubmit));
    await tester.pump(); // start the request, don't settle — it's gated open

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    // Typing into a locked field changes nothing, so what the request
    // carries stays what was on screen when it started.
    await tester.enterText(find.byType(TextFormField), 'Honda');
    await tester.pump();

    dataSource.submitGate!.complete();
    await tester.pumpAndSettle();

    expect(dataSource.submittedFields!['brand'], 'Toyota');
    expect(find.text(l10n.stateSubmitSuccess), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('a load failure shows an error view with a working retry', (
    tester,
  ) async {
    final dataSource = _FakeDataSource(
      fetchError: const DataSourceNetworkException(),
    );
    await tester.pumpWidget(_harness(dataSource));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.errorNetwork), findsOneWidget);

    dataSource.fetchError = null;
    await tester.tap(find.text(l10n.actionRetry));
    await tester.pumpAndSettle();

    expect(find.textContaining('Brand'), findsWidgets);
  });
}
