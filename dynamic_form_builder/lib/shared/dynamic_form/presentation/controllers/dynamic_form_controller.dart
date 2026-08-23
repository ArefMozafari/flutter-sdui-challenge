import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/di.dart';
import '../../application/services/submit_form_result.dart';
import '../../domain/models/field_value.dart';
import '../../domain/models/form_spec.dart';
import '../states/dynamic_form_view_state.dart';

part 'dynamic_form_controller.g.dart';

/// Owns the form's lifecycle: fetch on load, hold field values as the user
/// types/picks, validate-and-submit on demand.
///
/// Calls [dynamicFormRepositoryProvider] directly for the fetch — not
/// through `DynamicFormService` — and [dynamicFormServiceProvider] for
/// submit. See the plan doc's "Skipping a boilerplate-only layer": fetching
/// has nothing for a Service to add, submitting does (validation +
/// Domain-to-Data translation), so only one of the two skips Application.
@riverpod
class DynamicFormController extends _$DynamicFormController {
  @override
  DynamicFormViewState build() {
    unawaited(_load());
    return const DynamicFormLoading();
  }

  Future<void> _load() async {
    final result = await ref.read(dynamicFormRepositoryProvider).fetchForm();
    state = result.match(
      DynamicFormLoadError.new,
      (spec) => DynamicFormLoaded(spec: spec, values: _initialValues(spec)),
    );
  }

  Map<String, FieldValue> _initialValues(FormSpec spec) => {
    for (final field in spec.fields) field.name: initialFieldValue(field),
  };

  /// Re-fetches after a load failure. Resets straight to [DynamicFormLoading]
  /// rather than trying to preserve anything — there's nothing to preserve
  /// yet, the form never loaded.
  Future<void> retryLoad() async {
    state = const DynamicFormLoading();
    await _load();
  }

  void updateValue(String fieldName, FieldValue value) {
    final current = state;
    if (current is! DynamicFormLoaded) return;

    state = DynamicFormLoaded(
      spec: current.spec,
      values: {...current.values, fieldName: value},
      // Editing a field clears its own stale error and any leftover
      // submit-failure banner from a previous attempt — both describe a
      // form state that no longer exists once the user changes something.
      fieldErrors: Map.of(current.fieldErrors)..remove(fieldName),
    );
  }

  Future<void> submit() async {
    final current = state;
    if (current is! DynamicFormLoaded || current.isSubmitting) return;

    state = DynamicFormLoaded(
      spec: current.spec,
      values: current.values,
      isSubmitting: true,
    );

    final result = await ref
        .read(dynamicFormServiceProvider)
        .submitForm(form: current.spec, values: current.values);

    state = switch (result) {
      SubmitFormSuccess() => DynamicFormLoaded(
        spec: current.spec,
        values: current.values,
        submitSucceeded: true,
      ),
      SubmitFormValidationFailed(:final fieldErrors) => DynamicFormLoaded(
        spec: current.spec,
        values: current.values,
        fieldErrors: fieldErrors,
      ),
      SubmitFormFailed(:final failure) => DynamicFormLoaded(
        spec: current.spec,
        values: current.values,
        submitFailure: failure,
      ),
    };
  }
}
