import 'dart:async';

import 'package:dio/dio.dart';

import 'package:dynamic_form_builder/core/network/api_client.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/datasource_exceptions.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';

/// The real counterpart to [MockDynamicFormDataSource] — structurally
/// complete (GET the form, POST a multipart submission), but there is no
/// real backend in this challenge to run it against. It's included, and
/// kept out of the default provider graph, specifically so
/// [DynamicFormDataSource] being an interface with two real implementations
/// is a true statement rather than a hypothetical one.
///
/// The actual network calls (`_client.get`, `_client.postMultipart`) have
/// no test — there's nothing genuine to assert without a live server. But
/// [buildSubmitFormData] is pure Dart with no I/O, so it's extracted and
/// tested directly instead of living inline: a map literal like
/// `{for (final f in files) f.fieldName: MultipartFile.fromBytes(...)}`
/// looks reasonable but silently keeps only the *last* file for a field
/// that gets more than one, since Dart map literals drop earlier entries
/// for a repeated key — exactly the kind of bug "there's nothing to test
/// here" reasoning misses.
class HttpDynamicFormDataSource implements DynamicFormDataSource {
  const HttpDynamicFormDataSource(this._client, {required this.formPath});

  final ApiClient _client;

  /// Path to GET the form spec from, e.g. `/api/forms/car_listing`. The
  /// submit destination isn't configured here — it comes back as part of
  /// the form spec itself (`submitUrl`) and is passed into [submitForm].
  final String formPath;

  @override
  Future<Map<String, dynamic>> fetchFormSpec() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(formPath);
      final data = response.data;
      if (data == null) {
        throw const FormatException('empty response body');
      }
      return data;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> submitForm({
    required String submitUrl,
    required Map<String, dynamic> fields,
    required List<SubmissionFile> files,
  }) async {
    try {
      final formData = buildSubmitFormData(fields, files);
      await _client.postMultipart(submitUrl, formData);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => TimeoutException(e.message),
      DioExceptionType.badResponse => DataSourceServerException(
        e.response?.statusCode ?? 0,
      ),
      DioExceptionType.connectionError => const DataSourceNetworkException(),
      _ => DataSourceNetworkException(e.message ?? 'unknown network error'),
    };
  }
}

/// Builds the multipart body for a submission — pure Dart, no I/O, so it's
/// a top-level function rather than a private method: that's what makes it
/// testable without touching the network at all.
///
/// [files] is grouped by [SubmissionFile.fieldName] before reaching
/// [FormData.fromMap], not added as repeated `fieldName: file` map entries
/// — a Dart map literal silently keeps only the *last* entry for a
/// duplicate key, which would drop every picked file but the last one for
/// a field that allows more than one (`car_images` allows up to 10).
/// `FormData.fromMap` expands a `List<MultipartFile>` value into one
/// repeated field per element instead.
FormData buildSubmitFormData(
  Map<String, dynamic> fields,
  List<SubmissionFile> files,
) {
  final filesByField = <String, List<MultipartFile>>{};
  for (final file in files) {
    (filesByField[file.fieldName] ??= []).add(
      MultipartFile.fromBytes(file.bytes, filename: file.fileName),
    );
  }
  return FormData.fromMap({...fields, ...filesByField});
}
