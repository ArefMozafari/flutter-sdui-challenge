import 'dart:async';

import 'package:dynamic_form_builder/features/dynamic_form/data/datasources/datasource_exceptions.dart';
import 'package:dynamic_form_builder/features/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/features/dynamic_form/data/repositories/dynamic_form_repository.dart';
import 'package:dynamic_form_builder/features/dynamic_form/domain/failures/failure.dart';
import 'package:flutter_test/flutter_test.dart';

/// No `implements` interface needed on the production side (see
/// DynamicFormRepository's own doc comment) — but DynamicFormDataSource
/// *is* abstract, so this fake implements it directly, no mocking
/// framework required.
class _FakeDataSource implements DynamicFormDataSource {
  _FakeDataSource({this.fetchResult, this.submitError});

  /// Either a JSON map to return, or an error to throw, from
  /// [fetchFormSpec].
  final Object? fetchResult;

  /// An error to throw from [submitForm]; null means succeed.
  final Object? submitError;

  @override
  Future<Map<String, dynamic>> fetchFormSpec() async {
    if (fetchResult is Map<String, dynamic>) {
      return fetchResult as Map<String, dynamic>;
    }
    throw fetchResult!;
  }

  @override
  Future<void> submitForm({
    required String submitUrl,
    required Map<String, dynamic> fields,
    required List<SubmissionFile> files,
  }) async {
    if (submitError != null) throw submitError!;
  }
}

const _validForm = {
  'formId': 'car_listing',
  'version': 1,
  'submitUrl': '/api/forms/car_listing/submit',
  'fields': <Map<String, dynamic>>[],
};

void main() {
  group('fetchForm', () {
    test('a valid response maps to Right(FormSpec)', () async {
      final repo = DynamicFormRepository(
        _FakeDataSource(fetchResult: _validForm),
      );
      final result = await repo.fetchForm();
      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected Right'),
        (spec) => expect(spec.formId, 'car_listing'),
      );
    });

    test('TimeoutException maps to TimeoutFailure', () async {
      final repo = DynamicFormRepository(
        _FakeDataSource(fetchResult: TimeoutException('x')),
      );
      final result = await repo.fetchForm();
      expect(result.getLeft().toNullable(), isA<TimeoutFailure>());
    });

    test('DataSourceNetworkException maps to NetworkFailure', () async {
      final repo = DynamicFormRepository(
        _FakeDataSource(fetchResult: const DataSourceNetworkException()),
      );
      final result = await repo.fetchForm();
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('DataSourceServerException maps to ServerFailure', () async {
      final repo = DynamicFormRepository(
        _FakeDataSource(fetchResult: const DataSourceServerException(500)),
      );
      final result = await repo.fetchForm();
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
    });

    test('FormatException maps to ParseFailure', () async {
      final repo = DynamicFormRepository(
        _FakeDataSource(fetchResult: const FormatException('bad json')),
      );
      final result = await repo.fetchForm();
      expect(result.getLeft().toNullable(), isA<ParseFailure>());
    });

    test('a malformed field (wrong shape) maps to ParseFailure', () async {
      final repo = DynamicFormRepository(
        _FakeDataSource(
          fetchResult: {
            'fields': [
              {'type': 'text', 'validation': <String, dynamic>{}},
            ],
          },
        ),
      );
      final result = await repo.fetchForm();
      expect(result.getLeft().toNullable(), isA<ParseFailure>());
    });

    test('any other error maps to UnexpectedFailure', () async {
      final repo = DynamicFormRepository(
        _FakeDataSource(fetchResult: StateError('boom')),
      );
      final result = await repo.fetchForm();
      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });
  });

  group('submitForm', () {
    test('success maps to Right(unit)', () async {
      final repo = DynamicFormRepository(_FakeDataSource());
      final result = await repo.submitForm(
        submitUrl: '/x',
        fields: const {},
        files: const [],
      );
      expect(result.isRight(), isTrue);
    });

    test('a server failure maps to ServerFailure', () async {
      final repo = DynamicFormRepository(
        _FakeDataSource(submitError: const DataSourceServerException(422)),
      );
      final result = await repo.submitForm(
        submitUrl: '/x',
        fields: const {},
        files: const [],
      );
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 422);
    });
  });
}
