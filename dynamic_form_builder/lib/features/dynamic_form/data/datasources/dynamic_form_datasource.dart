/// The one point where this app talks to a server.
///
/// Unlike [DynamicFormRepository][../repositories/dynamic_form_repository.dart],
/// this genuinely has two real implementations —
/// [MockDynamicFormDataSource][mock_dynamic_form_datasource.dart] and
/// [HttpDynamicFormDataSource][http_dynamic_form_datasource.dart] — that
/// must be interchangeable at runtime via a single Riverpod provider
/// override, not just swappable in tests. That's what earns the explicit
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
/// Distinct from Domain's `SelectedFileMeta`: that's metadata-only, enough
/// to validate against `FieldValidation` without Domain ever touching
/// bytes. This carries the actual bytes, because building a multipart
/// request is Data's job.
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
