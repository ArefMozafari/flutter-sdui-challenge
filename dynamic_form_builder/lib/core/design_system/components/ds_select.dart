import 'package:flutter/material.dart';

import 'ds_field_label.dart';
import 'ds_field_size.dart';

/// One selectable option: what the user sees ([label]) vs. what the caller
/// gets back ([value]) — kept apart because a server-declared option's
/// display label and its submission value are routinely different strings.
class DsSelectOption<T> {
  const DsSelectOption({required this.label, required this.value});

  final String label;
  final T value;
}

/// Single-choice dropdown. Generic over the option value type so callers
/// aren't forced through `String` and back.
class DsSelect<T> extends StatelessWidget {
  const DsSelect({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hintText,
    this.errorText,
    this.isRequired = false,
    this.size = DsFieldSize.medium,
    this.enabled = true,
  });

  final String label;
  final List<DsSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? hintText;
  final String? errorText;
  final bool isRequired;
  final DsFieldSize size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsFieldLabel(label, isRequired: isRequired),
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: enabled ? onChanged : null,
          style: size.textStyle.copyWith(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option.value, child: Text(option.label)),
          ],
        ),
      ],
    );
  }
}
