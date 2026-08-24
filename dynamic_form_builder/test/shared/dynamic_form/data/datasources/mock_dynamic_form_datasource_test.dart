import 'dart:async';
import 'dart:convert';

import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/datasource_exceptions.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/mock_dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/repositories/dynamic_form_repository.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/failures/failure.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a fixed string for any asset key, so these tests need neither the
/// real bundle nor a running binding.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.contents);

  final String contents;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(Uint8List.fromList(utf8.encode(contents)).buffer);
}

const _validSpec =
    '{"formId":"x","version":1,"submitUrl":"/submit","fields":[]}';

MockDynamicFormDataSource _source({
  MockFailureMode mode = MockFailureMode.none,
  String contents = _validSpec,
}) => MockDynamicFormDataSource(
  latency: Duration.zero,
  failureMode: mode,
  assetBundle: _FakeBundle(contents),
);

void main() {
  group('the happy path', () {
    test('fetchFormSpec decodes the bundled asset', () async {
      final json = await _source().fetchFormSpec();
      expect(json['formId'], 'x');
    });

    test('submitForm accepts a form when no failure is injected', () async {
      await expectLater(
        _source().submitForm(submitUrl: '/submit', fields: {}, files: []),
        completes,
      );
    });
  });

  group('injected failures', () {
    // The whole point of MockFailureMode is that the app's error states are
    // demonstrably built rather than assumed. Untested, that guarantee was
    // itself an assumption.
    const expected = <MockFailureMode, TypeMatcher<Object>>{
      MockFailureMode.network: TypeMatcher<DataSourceNetworkException>(),
      MockFailureMode.timeout: TypeMatcher<TimeoutException>(),
      MockFailureMode.server500: TypeMatcher<DataSourceServerException>(),
      MockFailureMode.malformedBody: TypeMatcher<FormatException>(),
    };

    for (final entry in expected.entries) {
      test('${entry.key.name} throws from fetchFormSpec', () {
        expect(
          () => _source(mode: entry.key).fetchFormSpec(),
          throwsA(entry.value),
        );
      });

      test('${entry.key.name} throws from submitForm', () {
        expect(
          () => _source(
            mode: entry.key,
          ).submitForm(submitUrl: '/submit', fields: {}, files: []),
          throwsA(entry.value),
        );
      });
    }

    test('server500 carries its status code', () {
      expect(
        () => _source(mode: MockFailureMode.server500).fetchFormSpec(),
        throwsA(
          isA<DataSourceServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('none throws nothing', () {
      expect(MockFailureMode.none.maybeThrow, returnsNormally);
    });
  });

  group('through the repository, each mode becomes its Failure', () {
    // What the user actually ends up seeing: the error state the injected
    // mode is meant to demonstrate.
    const expected = <MockFailureMode, TypeMatcher<Failure>>{
      MockFailureMode.network: TypeMatcher<NetworkFailure>(),
      MockFailureMode.timeout: TypeMatcher<TimeoutFailure>(),
      MockFailureMode.server500: TypeMatcher<ServerFailure>(),
      MockFailureMode.malformedBody: TypeMatcher<ParseFailure>(),
    };

    for (final entry in expected.entries) {
      test('${entry.key.name} surfaces as ${entry.value}', () async {
        final repository = DynamicFormRepository(_source(mode: entry.key));
        final result = await repository.fetchForm();
        expect(result.getLeft().toNullable(), entry.value);
      });
    }

    test('an unparsable asset body also surfaces as ParseFailure', () async {
      final repository = DynamicFormRepository(_source(contents: 'not json'));
      final result = await repository.fetchForm();
      expect(result.getLeft().toNullable(), isA<ParseFailure>());
    });
  });
}
