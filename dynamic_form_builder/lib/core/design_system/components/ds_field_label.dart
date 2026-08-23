import 'package:flutter/material.dart';

import 'package:dynamic_form_builder/core/design_system/tokens/app_spacing.dart';

/// Label shown above a form field, with a consistent required-marker style.
class DsFieldLabel extends StatelessWidget {
  const DsFieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: text),
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(color: scheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
