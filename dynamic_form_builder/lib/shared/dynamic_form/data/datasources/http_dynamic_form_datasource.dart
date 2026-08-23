import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import 'datasource_exceptions.dart';
import 'dynamic_form_datasource.dart';

/// The real counterpart to [MockDynamicFormDataSource] — structurally
/// complete (GET the form, POST a multipart submission), but there is no
/// real backend in this challenge to run it against. It's included, and
/// kept out of the default provider graph, specifically so
/// [DynamicFormDataSource] being an interface with two real implementations
/// is a true statement rather than a hypothetical one. It has no test:
/// there's nothing genuine to assert against without a live server, and a
/// test that only mocks Dio would just be re-asserting this file's own
/// logic back at itself.
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
      final formData = FormData.fromMap({
        ...fields,
        for (final file in files)
          file.fieldName: MultipartFile.fromBytes(
            file.bytes,
            filename: file.fileName,
          ),
      });
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
