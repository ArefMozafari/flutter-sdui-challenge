import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dynamic_form_builder/core/network/api_client.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/http_dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/mock_dynamic_form_datasource.dart';

/// Which [DynamicFormDataSource] a caller of [dynamicFormDataSourceProvider]
/// wants. A family provider, not a plain one overridden per-environment: the
/// choice is explicit at the one place it's actually consumed
/// (`dynamicFormRepositoryProvider`, in `dynamic_form_repository.dart`)
/// rather than implicit in whatever override happens to be active.
enum DataSourceImplementation { mock, http }

/// Declared beside the interface it provides, not either implementation —
/// there's no single class for `Command+Click` to land on, since this
/// genuinely constructs one of two. `mock`/`http` are both visible right
/// here, next to [DynamicFormDataSource] itself, rather than hidden behind
/// a provider override somewhere else.
final dynamicFormDataSourceProvider =
    Provider.family<DynamicFormDataSource, DataSourceImplementation>((
      ref,
      implementation,
    ) {
      return switch (implementation) {
        DataSourceImplementation.mock => MockDynamicFormDataSource(),
        DataSourceImplementation.http => HttpDynamicFormDataSource(
          ref.watch(apiClientProvider),
          formPath: '/api/forms/car_listing',
        ),
      };
    });

/// The one point where this app talks to a server.
///
/// Unlike `DynamicFormRepository`, this genuinely has two real
/// implementations — [MockDynamicFormDataSource] and
/// [HttpDynamicFormDataSource] — that's what earns the explicit
/// `abstract class` here, where the Repository (one real implementation)
/// does without one.
///
/// Returns/throws at the transport level — raw JSON in, raw exceptions out
/// (see `datasource_exceptions.dart`). Mapping those into Domain's
/// `Either<Failure, T>` is the Repository's job, not this layer's.
abstract class DynamicFormDataSource {
  Future<Map<String, dynamic>> fetchFormSpec();

  Future<void> submitForm({
    required String submitUrl,
    required Map<String, dynamic> fields,
    required List<SubmissionFile> files,
  });
}

/// One file to upload, keyed to the form field it belongs to.
///
/// Distinct from Domain's `SelectedFile`: that one is grouped implicitly by
/// its position in a `Map<String, FieldValue>` (no field name needed
/// inside it). This is the flat, wire-ready shape `submitForm` sends as one
/// list across every field, so it needs [fieldName] carried explicitly.
class SubmissionFile {
  const SubmissionFile({
    required this.fieldName,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fieldName;
  final String fileName;
  final String mimeType;
  final List<int> bytes;
}
