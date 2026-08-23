import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'datasource_exceptions.dart';
import 'dynamic_form_datasource.dart';

/// A failure to simulate on the next call, so the app's error states are
/// demonstrably built and exercised — not just assumed to work because the
/// happy path does.
enum MockFailureMode {
  none,
  network,
  timeout,
  server500,
  malformedBody;

  /// Throws the exception this mode represents, or does nothing for [none].
  void maybeThrow() {
    switch (this) {
      case MockFailureMode.none:
        return;
      case MockFailureMode.network:
        throw const DataSourceNetworkException();
      case MockFailureMode.timeout:
        throw TimeoutException('mock request timed out');
      case MockFailureMode.server500:
        throw const DataSourceServerException(500);
      case MockFailureMode.malformedBody:
        throw const FormatException('mock malformed response body');
    }
  }
}

/// Reads the form spec from a bundled asset instead of a real network call.
/// Backed by [assetBundle] rather than the global `rootBundle` directly so
/// tests can inject one that doesn't need a running Flutter binding.
class MockDynamicFormDataSource implements DynamicFormDataSource {
  MockDynamicFormDataSource({
    this.latency = const Duration(milliseconds: 400),
    this.failureMode = MockFailureMode.none,
    AssetBundle? assetBundle,
  }) : assetBundle = assetBundle ?? rootBundle;

  static const _formAssetPath = 'assets/mock/car_listing_form.json';

  final Duration latency;
  final MockFailureMode failureMode;
  final AssetBundle assetBundle;

  @override
  Future<Map<String, dynamic>> fetchFormSpec() async {
    await Future<void>.delayed(latency);
    failureMode.maybeThrow();

    final raw = await assetBundle.loadString(_formAssetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> submitForm({
    required String submitUrl,
    required Map<String, dynamic> fields,
    required List<SubmissionFile> files,
  }) async {
    await Future<void>.delayed(latency);
    failureMode.maybeThrow();
    // No real backend to POST to — a form that reaches here is accepted.
  }
}
