import 'package:flutter/material.dart';

import 'ds_field_label.dart';
import 'ds_field_size.dart';

/// Single- or multi-line text input. Owns its own [TextEditingController] so
/// the caller's rebuilds (e.g. a Riverpod state change on an unrelated
/// field) never reset the cursor position — [initialValue] seeds the field
/// once; after that, this widget is the source of truth for the raw text,
/// and [onChanged] is how the caller finds out what the user typed.
class DsTextField extends StatefulWidget {
  const DsTextField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.hintText,
    this.errorText,
    this.isRequired = false,
    this.keyboardType,
    this.maxLines = 1,
    this.size = DsFieldSize.medium,
    this.enabled = true,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String? initialValue;
  final String? hintText;
  final String? errorText;
  final bool isRequired;
  final TextInputType? keyboardType;
  final int maxLines;
  final DsFieldSize size;
  final bool enabled;

  @override
  State<DsTextField> createState() => _DsTextFieldState();
}

class _DsTextFieldState extends State<DsTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsFieldLabel(widget.label, isRequired: widget.isRequired),
        TextFormField(
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          style: widget.size.textStyle,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: widget.errorText,
          ),
        ),
      ],
    );
  }
}
