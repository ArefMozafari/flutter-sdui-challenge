import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/form_field_spec.dart';

/// What renders for an [UnsupportedFieldSpec] — a server field type this
/// build doesn't recognize. Visible in debug (so the gap is obvious while
/// developing against a server that's ahead of the app), silently skipped
/// in release (so a user never sees a "coming soon" placeholder for a
/// field they can't do anything about) — see decision #3 in the plan doc.
class UnsupportedFieldRenderer extends StatelessWidget {
  const UnsupportedFieldRenderer({super.key, required this.spec});

  final UnsupportedFieldSpec spec;

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
            Text(l10n.fieldUnsupportedBody(spec.rawType)),
          ],
        ),
      ),
    );
  }
}
