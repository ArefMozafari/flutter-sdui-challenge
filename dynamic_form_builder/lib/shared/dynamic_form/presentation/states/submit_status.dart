import 'package:dynamic_form_builder/shared/dynamic_form/application/services/submit_form_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/failures/failure.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';

/// Where the form's submit attempt currently stands.
///
/// Sealed, like every other closed variant set in this codebase, because
/// these five cases are mutually exclusive and always were: a form is never
/// submitting *and* succeeded, never rejected *and* failed.
///
/// An earlier version modelled them as four independent optional flags on
/// `DynamicFormLoaded` (`isSubmitting`, `submitSucceeded`, `submitFailure`,
/// `fieldErrors`). Every transition rebuilt that object from scratch, so any
/// flag a call site didn't mention silently reverted to its default — which
/// is exactly how an edit made mid-submit came to cancel the in-flight
/// submit. One field that must be set explicitly replaces four that could
/// each be forgotten; see ARCHITECTURE.md.
sealed class SubmitStatus {
  const SubmitStatus();
}

/// Nothing to report: either the form was never submitted, or the user has
/// edited it since, which retires whatever the last attempt said.
final class SubmitIdle extends SubmitStatus {
  const SubmitIdle();
}

/// A request is in flight. The view locks every field for as long as this
/// holds, so the values being submitted can't drift underneath the request.
final class SubmitInProgress extends SubmitStatus {
  const SubmitInProgress();
}

final class SubmitSucceeded extends SubmitStatus {
  const SubmitSucceeded();
}

/// Client-side validation rejected the form — it never reached the server.
/// Carries one [ValidationResult] per offending field.
final class SubmitRejected extends SubmitStatus {
  const SubmitRejected(this.fieldErrors);

  final Map<String, ValidationResult> fieldErrors;
}

/// The request left the device and came back a [Failure].
///
/// Distinct from [SubmitRejected] (which never left) and — despite the
/// similar name — from Application's [SubmitFormFailed], which is the
/// *result* this status is derived from, not the status itself.
final class SubmitFailed extends SubmitStatus {
  const SubmitFailed(this.failure);

  final Failure failure;
}
