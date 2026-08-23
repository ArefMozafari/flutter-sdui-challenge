import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../domain/failures/failure.dart';
import '../../domain/models/form_spec.dart';
import '../datasources/datasource_exceptions.dart';
import '../datasources/dynamic_form_datasource.dart';
import '../dto/form_spec_dto.dart';

/// Composes a [DynamicFormDataSource] with DTO mapping — the one place
/// wire data crosses into Domain shapes.
///
/// No abstract interface, unlike [DynamicFormDataSource]: there is exactly
/// one Repository implementation, so Dart classes being implicitly their
/// own interface is enough — `class FakeDynamicFormRepository implements
/// DynamicFormRepository` works in tests without a separate `abstract
/// class` declaration earning no real cost reduction. The actual test seam
/// is Riverpod's provider override, not a hand-rolled interface.
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
