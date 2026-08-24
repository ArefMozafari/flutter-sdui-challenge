import 'package:dynamic_form_builder/shared/dynamic_form/domain/failures/failure.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/states/submit_status.dart';

/// What `DynamicFormView` renders, owned by Presentation — sealed for the
/// same compile-time-exhaustiveness reason as `FormFieldSpec` and
/// `Failure`. Only three top-level cases (loading/load-error/loaded): a form
/// stays loaded and on screen throughout a submit attempt, so how that
/// attempt is going lives in [DynamicFormLoaded.status] rather than in
/// further subtypes here.
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
    this.status = const SubmitIdle(),
  });

  final FormSpec spec;
  final Map<String, FieldValue> values;

  /// How the submit attempt is going, as one value rather than a set of
  /// independent flags — see [SubmitStatus] for why that distinction is
  /// what keeps a state transition from silently dropping half of it.
  final SubmitStatus status;

  /// Derived, never stored: nothing can set this out of agreement with
  /// [status], which is the whole point of it not being its own field.
  bool get isSubmitting => status is SubmitInProgress;

  /// The per-field errors to show right now. Only a [SubmitRejected] carries
  /// any — this form validates on submit, never live as the user types.
  Map<String, ValidationResult> get fieldErrors => switch (status) {
    SubmitRejected(:final fieldErrors) => fieldErrors,
    _ => const {},
  };
}
