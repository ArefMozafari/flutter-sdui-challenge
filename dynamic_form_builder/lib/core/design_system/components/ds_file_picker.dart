import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'ds_field_label.dart';

/// Purely presentational file-selection field: shows the currently selected
/// file names and a trigger button. It never talks to `file_picker` (or any
/// platform plugin) itself, and it knows nothing about accepted mime types
/// or size limits — those are validation rules that belong to a specific
/// server-declared field, so the actual picking + constraint-checking
/// happens one layer up, in the field renderer that owns that context. This
/// widget only renders what it's told and reports taps.
class DsFilePicker extends StatelessWidget {
  const DsFilePicker({
    super.key,
    required this.label,
    required this.fileNames,
    required this.onPickRequested,
    required this.pickButtonLabel,
    this.onRemove,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
  });

  final String label;
  final List<String> fileNames;
  final VoidCallback onPickRequested;
  final String pickButtonLabel;
  final ValueChanged<int>? onRemove;
  final String? errorText;
  final bool isRequired;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsFieldLabel(label, isRequired: isRequired),
        if (fileNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (index, name) in fileNames.indexed)
                  Chip(
                    label: Text(name, overflow: TextOverflow.ellipsis),
                    onDeleted: onRemove == null ? null : () => onRemove!(index),
                  ),
              ],
            ),
          ),
        OutlinedButton(
          onPressed: enabled ? onPickRequested : null,
          child: Text(pickButtonLabel),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
