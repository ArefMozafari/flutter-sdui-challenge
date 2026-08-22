import 'package:dio/dio.dart';

/// A thin wrapper around [Dio] — transport only. Deliberately has no idea
/// `Failure` exists: it belongs to `core` precisely because it doesn't know
/// `dynamic_form` exists either (see the `core/` boundary rule). Mapping a
/// [DioException] into something meaningful is every caller's own job —
/// here, `HttpDynamicFormDataSource`.
class ApiClient {
  ApiClient({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: connectTimeout,
               receiveTimeout: receiveTimeout,
             ),
           );

  final Dio _dio;

  Future<Response<T>> get<T>(String path) => _dio.get<T>(path);

  Future<Response<T>> postMultipart<T>(String path, FormData data) =>
      _dio.post<T>(path, data: data);
}
