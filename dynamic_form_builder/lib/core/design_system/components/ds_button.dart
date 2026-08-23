import 'package:flutter/material.dart';

import 'package:dynamic_form_builder/core/design_system/tokens/app_spacing.dart';

/// Primary action button with a built-in loading state — every
/// submit/retry/async-triggering button in the app uses this instead of
/// hand-rolling its own spinner-and-disable logic.
class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: AppSpacing.lg,
              width: AppSpacing.lg,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
