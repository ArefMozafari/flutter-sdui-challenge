import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dynamic_form_builder/core/design_system/tokens/app_spacing.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';

/// Renders in place of a field this build can't show. Visible in debug (so
/// the gap is obvious while developing against a server that's ahead of the
/// app), silently skipped in release (so a user never sees a "coming soon"
/// placeholder for a field they can't do anything about) — see decision #3
/// in the plan doc.
///
/// Two ways to get here, and they are not the same kind of problem:
///
/// - The default constructor takes an [UnsupportedFieldSpec] — a *data*
///   condition. The server declared a type this build doesn't know, which is
///   expected whenever the backend is ahead of the app.
/// - [UnsupportedFieldRenderer.forUnrendered] takes any other
///   [FormFieldSpec] — a *programming* error. The type is known to Domain
///   but `FieldWidgetRegistry` has no entry for it.
class UnsupportedFieldRenderer extends StatelessWidget {
  const UnsupportedFieldRenderer({
    super.key,
    required UnsupportedFieldSpec this.spec,
  });

  /// For a [FormFieldSpec] subtype the widget registry has no builder for.
  ///
  /// Exists so the registry's fallback can't throw: it used to cast to
  /// [UnsupportedFieldSpec] unconditionally, which turned a missing registry
  /// entry into a `TypeError` on screen — the exact runtime crash the
  /// registry's design is supposed to rule out.
  ///
  /// Note what this does *not* fix: the field still reaches Domain, so it is
  /// seeded into the value map and validated like any other. If it is
  /// required, the form can't be submitted and the offending field isn't on
  /// screen to fix. The compiler catches a new subtype everywhere else
  /// (`initialFieldValue`, `validateField` are exhaustive switches) — the
  /// registry is the one place it doesn't, so a missing entry has to be
  /// caught in review.
  const UnsupportedFieldRenderer.forUnrendered(this.spec, {super.key});

  final FormFieldSpec spec;

  /// What to name the offending type in the message. The server's own string
  /// when there is one, otherwise the Dart type — which is what a developer
  /// needs, and this only ever renders in debug.
  String get _typeLabel => switch (spec) {
    UnsupportedFieldSpec(:final rawType) => rawType,
    _ => spec.runtimeType.toString(),
  };

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fieldUnsupportedTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(l10n.fieldUnsupportedBody(_typeLabel)),
          ],
        ),
      ),
    );
  }
}
