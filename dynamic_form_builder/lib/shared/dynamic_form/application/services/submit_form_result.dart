import 'package:dynamic_form_builder/shared/dynamic_form/domain/failures/failure.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';

/// The outcome of [DynamicFormService.submitForm][dynamic_form_service.dart].
///
/// Sealed over two distinct kinds of failure, not one: a client-side
/// validation problem (never reached the network) and a server-side
/// [Failure] (network/timeout/server/parse — the repository actually tried
/// and it didn't work). Presentation needs to tell these apart to show the
/// right thing — inline field errors for the first, a retry-able banner for
/// the second — so collapsing them into one `Either<Failure, T>` would just
/// make Presentation re-derive the distinction from a generic error.
sealed class SubmitFormResult {
  const SubmitFormResult();
}

final class SubmitFormSuccess extends SubmitFormResult {
  const SubmitFormSuccess();
}

/// At least one field failed validation — the repository was never called.
final class SubmitFormValidationFailed extends SubmitFormResult {
  const SubmitFormValidationFailed(this.fieldErrors);

  /// Only the fields that failed — every value here is an `InvalidResult`.
  final Map<String, ValidationResult> fieldErrors;
}

final class SubmitFormFailed extends SubmitFormResult {
  const SubmitFormFailed(this.failure);
  final Failure failure;
}
