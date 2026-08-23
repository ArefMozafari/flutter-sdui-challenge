import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/components/ds_file_picker.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/field_value.dart';
import '../../domain/models/form_field_spec.dart';
import '../../domain/validation/validation_result.dart';
import 'validation_message_resolver.dart';

/// Renders a [FileFieldSpec]. This is the one renderer that actually talks
/// to a platform plugin (`file_picker`) — `DsFilePicker` itself is purely
/// presentational and knows nothing about picking or mime types, by
/// design (see its own doc comment); that logic belongs one layer up, here,
/// where the field's own [FieldValidation] (accept/maxFiles) is in scope.
class FileFieldRenderer extends StatefulWidget {
  const FileFieldRenderer({
    super.key,
    required this.spec,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final FileFieldSpec spec;
  final FileValue value;
  final ValidationResult? error;
  final ValueChanged<FieldValue> onChanged;

  @override
  State<FileFieldRenderer> createState() => _FileFieldRendererState();
}

class _FileFieldRendererState extends State<FileFieldRenderer> {
  bool _isPicking = false;

  Future<void> _pickFiles() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final type = _fileTypeFor(widget.spec.validation.accept);
      final picked = widget.spec.validation.maxFiles == 1
          ? await _pickSingle(type)
          : await FilePicker.pickFiles(type: type);
      if (picked.isEmpty) return;

      final selected = <SelectedFile>[];
      for (final file in picked) {
        selected.add(
          SelectedFile(
            name: file.name,
            mimeType: _guessMimeType(file.name),
            bytes: await file.readAsBytes(),
          ),
        );
      }
      widget.onChanged(FileValue([...widget.value.files, ...selected]));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<List<PlatformFile>> _pickSingle(FileType type) async {
    final file = await FilePicker.pickFile(type: type);
    return file == null ? const [] : [file];
  }

  void _removeAt(int index) {
    final updated = [...widget.value.files]..removeAt(index);
    widget.onChanged(FileValue(updated));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DsFilePicker(
      label: widget.spec.label,
      fileNames: [for (final file in widget.value.files) file.name],
      onPickRequested: _pickFiles,
      pickButtonLabel: l10n.actionPickFile,
      onRemove: _removeAt,
      errorText: resolveValidationMessage(l10n, widget.error),
      isRequired: widget.spec.validation.required,
      enabled: !_isPicking,
    );
  }
}

/// `image/*` maps to the platform's native image picker; anything else
/// falls back to an unfiltered picker — full mime-pattern-to-extension
/// filtering isn't worth building for the one `accept` pattern this
/// challenge's schema actually uses.
FileType _fileTypeFor(List<String>? accept) {
  if (accept != null && accept.every((a) => a.startsWith('image/'))) {
    return FileType.image;
  }
  return FileType.any;
}

const _extensionMimeTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'pdf': 'application/pdf',
};

String _guessMimeType(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot == -1) return 'application/octet-stream';
  final extension = fileName.substring(dot + 1).toLowerCase();
  return _extensionMimeTypes[extension] ?? 'application/octet-stream';
}
