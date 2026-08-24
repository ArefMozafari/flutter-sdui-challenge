import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dynamic_form_builder/shared/dynamic_form/application/services/dynamic_form_service.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/application/services/submit_form_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/data/repositories/dynamic_form_repository.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/states/dynamic_form_view_state.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/states/submit_status.dart';

/// Declared here, above the class it provides, rather than generated —
/// `Command+Click` lands directly on [DynamicFormController] with zero
/// hops. Kept alive for the app's lifetime rather than `.autoDispose`:
/// this repo has exactly one screen, always mounted, so there's no point
/// in the app where disposing the form's state would ever be correct.
final dynamicFormControllerProvider =
    NotifierProvider<DynamicFormController, DynamicFormViewState>(
      DynamicFormController.new,
    );

/// Owns the form's lifecycle: fetch on load, hold field values as the user
/// types/picks, validate-and-submit on demand.
///
/// Calls [dynamicFormRepositoryProvider] directly for the fetch — not
/// through `DynamicFormService` — and [dynamicFormServiceProvider] for
/// submit. See the plan doc's "Skipping a boilerplate-only layer": fetching
/// has nothing for a Service to add, submitting does (validation +
/// Domain-to-Data translation), so only one of the two skips Application.
class DynamicFormController extends Notifier<DynamicFormViewState> {
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

    // Values are frozen for as long as a request is in flight. The view
    // already locks every field over exactly that window, so this costs the
    // user nothing — it makes the freeze the controller's own guarantee
    // rather than something the view is trusted to enforce, which is what
    // keeps a submitted payload from ever disagreeing with what was on
    // screen when the success banner appears.
    if (current.isSubmitting) return;

    state = DynamicFormLoaded(
      spec: current.spec,
      values: {...current.values, fieldName: value},
      status: _statusAfterEditing(fieldName, current.status),
    );
  }

  /// What an edit does to the submit status. Exhaustive on purpose: a new
  /// [SubmitStatus] case can't be added without deciding, here, what editing
  /// a field means for it.
  SubmitStatus _statusAfterEditing(String fieldName, SubmitStatus current) =>
      switch (current) {
        // Unreachable — [updateValue] returns before this while a request is
        // in flight. Kept so the switch stays total, and so that dropping
        // that guard can't silently go back to retiring a live submit: that
        // is what re-enabled the submit button mid-request (letting a second
        // request start) and unlocked the fields underneath it.
        SubmitInProgress status => status,
        // Drop only this field's error; the others still describe values the
        // user hasn't touched since they were flagged.
        SubmitRejected(:final fieldErrors) => _rejectedOrIdle(
          Map.of(fieldErrors)..remove(fieldName),
        ),
        // A success or failure banner describes a form that no longer exists
        // the moment the user changes something in it.
        SubmitIdle() ||
        SubmitSucceeded() ||
        SubmitFailed() => const SubmitIdle(),
      };

  /// A rejection with nothing left to report is just [SubmitIdle] — without
  /// this, clearing the last error would leave the form "rejected" with an
  /// empty error map.
  SubmitStatus _rejectedOrIdle(Map<String, ValidationResult> fieldErrors) =>
      fieldErrors.isEmpty ? const SubmitIdle() : SubmitRejected(fieldErrors);

  Future<void> submit() async {
    final current = state;
    if (current is! DynamicFormLoaded || current.isSubmitting) return;

    state = DynamicFormLoaded(
      spec: current.spec,
      values: current.values,
      status: const SubmitInProgress(),
    );

    final result = await ref
        .read(dynamicFormServiceProvider)
        .submitForm(form: current.spec, values: current.values);

    // Re-read instead of reusing `current`: writing that stale object back
    // would undo anything that happened during the await. Fields are locked
    // while [SubmitInProgress], so values can't have drifted — but a reload
    // can still have replaced the form underneath this request, and its
    // result must not clobber the fresh one.
    final latest = state;
    if (latest is! DynamicFormLoaded || !latest.isSubmitting) return;

    state = DynamicFormLoaded(
      spec: latest.spec,
      values: latest.values,
      status: switch (result) {
        SubmitFormSuccess() => const SubmitSucceeded(),
        SubmitFormValidationFailed(:final fieldErrors) => SubmitRejected(
          fieldErrors,
        ),
        SubmitFormFailed(:final failure) => SubmitFailed(failure),
      },
    );
  }
}
