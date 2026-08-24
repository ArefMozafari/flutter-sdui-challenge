import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:dynamic_form_builder/core/design_system/components/ds_file_picker.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/validation/validation_result.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/validation_message_resolver.dart';

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
    this.enabled = true,
  });

  final FileFieldSpec spec;
  final FileValue value;
  final ValidationResult? error;
  final ValueChanged<FieldValue> onChanged;

  /// False while a submit is in flight, so the files being sent can't
  /// change underneath the request. Combines with this renderer's own
  /// [_FileFieldRendererState._isPicking] guard, which covers the unrelated
  /// case of a picker already being open.
  final bool enabled;

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
      widget.onChanged(
        FileValue(
          mergePickedFiles(
            existing: widget.value.files,
            picked: selected,
            maxFiles: widget.spec.validation.maxFiles,
          ),
        ),
      );
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
      enabled: widget.enabled && !_isPicking,
    );
  }
}

/// What the field holds after a pick.
///
/// A single-file field **replaces**; anything else appends. Picking on a
/// field that accepts one file means "this one instead" — appending there
/// left the user holding two files after a change of mind, which validation
/// then rejected at submit with "too many files", for a state the UI had
/// invited them into. Escaping it meant finding the remove control.
///
/// Overflowing a *multi*-file field is deliberately left to submit-time
/// validation instead of being capped here. That one is a real validation
/// condition the user chose and can fix by removing files, and this form
/// validates on submit by design. The single-file case isn't overflow at
/// all — it's the interaction meaning something different from what the
/// code did with it.
///
/// Pure and top-level so it can be tested without the platform picker,
/// which is a static call with no seam to fake.
List<SelectedFile> mergePickedFiles({
  required List<SelectedFile> existing,
  required List<SelectedFile> picked,
  required int? maxFiles,
}) {
  if (maxFiles == 1) return picked;
  return [...existing, ...picked];
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
