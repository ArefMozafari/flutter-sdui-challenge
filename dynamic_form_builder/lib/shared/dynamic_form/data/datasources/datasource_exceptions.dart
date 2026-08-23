/// Exceptions a [DynamicFormDataSource] implementation can throw.
///
/// Deliberately Data-owned, not Domain's `Failure` — a `DataSource` throws
/// what actually went wrong at the transport level; mapping that into a
/// `Failure` is the Repository's job, at the one boundary decision #4 says
/// it happens. `TimeoutException` (dart:async) and `FormatException`
/// (dart:core) cover the other two cases without needing dedicated types
/// here.
library;

class DataSourceNetworkException implements Exception {
  const DataSourceNetworkException([this.message = 'no network connection']);

  final String message;

  @override
  String toString() => 'DataSourceNetworkException: $message';
}

class DataSourceServerException implements Exception {
  const DataSourceServerException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'DataSourceServerException: $statusCode';
}
