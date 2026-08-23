import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/datasource_exceptions.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/dto/form_spec_dto.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/failures/failure.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_spec.dart';

/// Declared beside the class it constructs, like every other provider in
/// this codebase — `Command+Click` on a call site lands directly on
/// [DynamicFormRepository]. The mock↔real swap point lives one level down,
/// in [dynamicFormDataSourceProvider] — see that provider's own doc
/// comment for why it isn't here instead.
final dynamicFormRepositoryProvider = Provider<DynamicFormRepository>((ref) {
  return DynamicFormRepository(ref.watch(dynamicFormDataSourceProvider));
});

/// Composes a [DynamicFormDataSource] with DTO mapping — the one place
/// wire data crosses into Domain shapes.
///
/// No abstract interface, unlike [DynamicFormDataSource]: there is exactly
/// one Repository implementation, so Dart classes being implicitly their
/// own interface is enough — `class FakeDynamicFormRepository implements
/// DynamicFormRepository` works in tests without a separate `abstract
/// class` declaration earning no real cost reduction. In practice, tests
/// that only need Presentation working end-to-end override
/// [dynamicFormRepositoryProvider] directly with a real `DynamicFormRepository`
/// wrapping a fake `DynamicFormDataSource`; tests of the Repository itself
/// just construct one by hand — no override machinery needed either way.
///
/// Every method returns `Either<Failure, T>` (fpdart). `try`/`catch`
/// happens exactly once per method, right here — this is the one boundary
/// a raw exception is allowed to cross, and it never gets past it.
class DynamicFormRepository {
  const DynamicFormRepository(this._dataSource);

  final DynamicFormDataSource _dataSource;

  Future<Either<Failure, FormSpec>> fetchForm() async {
    try {
      final json = await _dataSource.fetchFormSpec();
      return Right(FormSpecDto.fromJson(json));
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on DataSourceNetworkException {
      return const Left(NetworkFailure());
    } on DataSourceServerException catch (e) {
      return Left(ServerFailure(e.statusCode));
    } on FormatException catch (e) {
      return Left(ParseFailure(e.message));
    } on TypeError catch (e) {
      // A DTO field arrived the wrong shape (missing key, wrong type) —
      // still a parse problem, just one Dart surfaces as a cast failure
      // rather than a FormatException.
      return Left(ParseFailure('$e'));
    } catch (e) {
      return Left(UnexpectedFailure('$e'));
    }
  }

  Future<Either<Failure, Unit>> submitForm({
    required String submitUrl,
    required Map<String, dynamic> fields,
    required List<SubmissionFile> files,
  }) async {
    try {
      await _dataSource.submitForm(
        submitUrl: submitUrl,
        fields: fields,
        files: files,
      );
      return const Right(unit);
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on DataSourceNetworkException {
      return const Left(NetworkFailure());
    } on DataSourceServerException catch (e) {
      return Left(ServerFailure(e.statusCode));
    } catch (e) {
      return Left(UnexpectedFailure('$e'));
    }
  }
}
