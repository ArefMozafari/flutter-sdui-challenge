import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

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
            mimeType: resolveMimeType(file.name),
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

/// The type reported to the `accept` rule and sent with the upload.
///
/// Backed by `package:mime`'s database rather than a hand-written table.
/// The table this replaced knew seven extensions, so a `.bmp` or `.tiff` —
/// which the `FileType.image` picker legitimately offers — resolved to
/// `application/octet-stream`, failed the `image/*` accept rule, and was
/// rejected as an unsupported type. The app turned away a file its own
/// picker had just presented.
///
/// `package:mime` was already in the lock file as a transitive dependency;
/// this only promotes it to a direct one. It covers every extension the old
/// table did, `heic` included, and is case-insensitive.
///
/// A name the database doesn't recognise still falls back to
/// `application/octet-stream`, which keeps the `accept` rule meaningful:
/// "we can't tell what this is" has to fail a rule that names specific
/// types, or the rule stops being a rule. That path is now rare enough to
/// be a real answer rather than the everyday one it used to be.
String resolveMimeType(String fileName) =>
    lookupMimeType(fileName) ?? 'application/octet-stream';
