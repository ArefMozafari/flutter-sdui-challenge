import '../../application/services/submit_form_result.dart';
import '../../domain/failures/failure.dart';
import '../../domain/models/field_value.dart';
import '../../domain/models/form_spec.dart';
import '../../domain/validation/validation_result.dart';

/// What `DynamicFormView` renders, owned by Presentation — sealed for the
/// same compile-time-exhaustiveness reason as `FormFieldSpec` and
/// `Failure`. Only three top-level cases (loading/load-error/loaded): the
/// submit-in-progress/error/success sub-states all live as flags on
/// [DynamicFormLoaded] rather than as further sealed subtypes, since a form
/// stays loaded and interactive throughout a submit attempt — sub-sealing
/// would just multiply into a loaded × submitting × error cross product
/// for no real benefit.
sealed class DynamicFormViewState {
  const DynamicFormViewState();
}

final class DynamicFormLoading extends DynamicFormViewState {
  const DynamicFormLoading();
}

final class DynamicFormLoadError extends DynamicFormViewState {
  const DynamicFormLoadError(this.failure);
  final Failure failure;
}

final class DynamicFormLoaded extends DynamicFormViewState {
  const DynamicFormLoaded({
    required this.spec,
    required this.values,
    this.fieldErrors = const {},
    this.isSubmitting = false,
    this.submitFailure,
    this.submitSucceeded = false,
  });

  final FormSpec spec;
  final Map<String, FieldValue> values;

  /// Only set after a submit attempt returns [SubmitFormValidationFailed] —
  /// this form never validates live as the user types (see the plan doc:
  /// validation runs on submit).
  final Map<String, ValidationResult> fieldErrors;

  final bool isSubmitting;

  /// Set only after a [SubmitFormFailed] — a server-side failure, distinct
  /// from [fieldErrors] (a client-side one). Both can't be set at once: a
  /// submit attempt resolves to exactly one of validation-failed,
  /// server-failed, or succeeded.
  final Failure? submitFailure;

  final bool submitSucceeded;
}
