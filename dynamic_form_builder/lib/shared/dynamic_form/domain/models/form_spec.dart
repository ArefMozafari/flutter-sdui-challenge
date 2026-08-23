import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';

/// The whole form, as fetched from the server and restructured into the
/// domain shape (see `dto/form_spec_dto.dart` for the wire mapping).
class FormSpec {
  const FormSpec({
    required this.formId,
    required this.version,
    required this.submitUrl,
    required this.fields,
  });

  final String formId;
  final int version;
  final String submitUrl;
  final List<FormFieldSpec> fields;
}
