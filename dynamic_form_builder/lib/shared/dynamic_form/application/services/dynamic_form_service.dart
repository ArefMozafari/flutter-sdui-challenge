import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dynamic_form_builder/shared/dynamic_form/application/services/submit_form_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/datasources/dynamic_form_datasource.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/repositories/dynamic_form_repository.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/field_validator.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';

/// Declared beside the class it provides — `Command+Click` on a call site
/// lands directly on [DynamicFormService].
final dynamicFormServiceProvider = Provider<DynamicFormService>((ref) {
  return DynamicFormService(ref.watch(dynamicFormRepositoryProvider));
});

/// Validates the whole form, then submits it. This is the one operation of
/// `dynamic_form` kept behind Application rather than skipped straight to
/// the Repository (see the plan doc's "Skipping a boilerplate-only layer"):
/// it validates-then-short-circuits (never calls the Repository on an
/// invalid form) and translates Presentation's Domain-shaped `FieldValue`s
/// into the Data-shaped `SubmissionFile`s the Repository wants — real work,
/// not pass-through. `fetchForm` has no method here at all: it would be a
/// one-line delegate, so the controller calls `DynamicFormRepository`
/// directly for it.
class DynamicFormService {
  const DynamicFormService(this._repository);

  final DynamicFormRepository _repository;

  Future<SubmitFormResult> submitForm({
    required FormSpec form,
    required Map<String, FieldValue> values,
  }) async {
    final fieldErrors = <String, ValidationResult>{};
    for (final field in form.fields) {
      if (field is UnsupportedFieldSpec) continue;
      final value = values[field.name] ?? initialFieldValue(field);
      final result = validateField(field, value);
      if (!result.isValid) fieldErrors[field.name] = result;
    }
    if (fieldErrors.isNotEmpty) {
      return SubmitFormValidationFailed(fieldErrors);
    }

    final fields = <String, Object>{};
    final submissionFiles = <SubmissionFile>[];
    for (final field in form.fields) {
      if (field is UnsupportedFieldSpec) continue;
      switch (values[field.name]) {
        // `trimmed`, not `text` — the same string validation measured.
        case TextValue(:final trimmed):
          fields[field.name] = trimmed;
        case NumberValue(number: final number?):
          fields[field.name] = number;
        case SelectValue(value: final value?):
          fields[field.name] = value;
        case FileValue(files: final pickedFiles):
          for (final picked in pickedFiles) {
            submissionFiles.add(
              SubmissionFile(
                fieldName: field.name,
                fileName: picked.name,
                mimeType: picked.mimeType,
                bytes: picked.bytes,
              ),
            );
          }
        case NumberValue() || SelectValue() || null:
        // Empty and optional (already passed validation above) — nothing
        // to submit for this field.
      }
    }

    final result = await _repository.submitForm(
      submitUrl: form.submitUrl,
      fields: fields,
      files: submissionFiles,
    );
    return result.match(SubmitFormFailed.new, (_) => const SubmitFormSuccess());
  }
}
