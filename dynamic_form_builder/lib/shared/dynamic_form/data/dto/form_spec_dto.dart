import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/dto/form_field_spec_dto.dart';

/// Parses the server's whole form response into a [FormSpec].
///
/// The legacy sample response is just `{"fields": [...]}` — no `formId`,
/// `version`, or `submitUrl` at all. Those three default to values that
/// only make sense for the compatibility-shim fixture (`legacy_form.json`
/// is a parser test, never actually submitted), never for the real
/// `car_listing_form.json`, which always sends all four keys.
class FormSpecDto {
  const FormSpecDto._();

  static FormSpec fromJson(Map<String, dynamic> json) {
    final rawFields = (json['fields'] as List).cast<Map<String, dynamic>>();
    return FormSpec(
      formId: json['formId'] as String? ?? 'legacy_form',
      version: json['version'] as int? ?? 1,
      submitUrl: json['submitUrl'] as String? ?? '',
      fields: rawFields.map(FormFieldSpecDto.fromJson).toList(),
    );
  }
}
