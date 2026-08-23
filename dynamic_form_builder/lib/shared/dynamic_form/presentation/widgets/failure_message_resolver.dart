import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/failures/failure.dart';

/// Resolves a Domain [Failure] into user-facing text. A plain `switch` (not
/// the key/args indirection [resolveValidationMessage] needs) works here
/// because [Failure] is a small, fixed sealed set with no per-instance
/// message arguments — there's nothing to reconnect.
String resolveFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorNetwork,
      TimeoutFailure() => l10n.errorTimeout,
      ServerFailure() => l10n.errorServer,
      ParseFailure() => l10n.errorParse,
      UnexpectedFailure() => l10n.errorGeneric,
    };
