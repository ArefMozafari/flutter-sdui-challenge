import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/http_dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/mock_dynamic_form_datasource.dart';

/// The actual mock↔real swap point: return a
/// `HttpDynamicFormDataSource(ref.watch(apiClientProvider), formPath: ...)`
/// instead of [MockDynamicFormDataSource] here to go live. Declared beside
/// the interface it provides, not either implementation — there's no
/// single class for `Command+Click` to land on, since this genuinely
/// constructs one of two.
///
/// Not a `Provider.family` keyed by an enum naming the same two
/// implementations again: nothing in this app ever watches the *other*
/// branch at the same time — there is exactly one caller
/// (`dynamicFormRepositoryProvider`) and it always wants whichever one
/// this body currently returns. A family adds a parameter to select
/// between two things a plain provider body already selects between just
/// as simply, for a dimension (which backend, at runtime) that doesn't
/// actually vary in this app.
final dynamicFormDataSourceProvider = Provider<DynamicFormDataSource>((ref) {
  return MockDynamicFormDataSource();
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
