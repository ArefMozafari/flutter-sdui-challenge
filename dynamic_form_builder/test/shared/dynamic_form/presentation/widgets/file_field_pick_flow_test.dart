import 'dart:typed_data';

import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_size_hint.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_validation.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/file_field_renderer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A picked file that never touches the platform.
///
/// `PlatformFile` is an `abstract base class`, so this has to extend it —
/// implementing it is refused outside its own library.
final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile(this._name, [this._bytes = const [1, 2, 3]]);

  final String _name;
  final List<int> _bytes;

  @override
  String get name => _name;

  @override
  Uri get uri => Uri.parse('file:///tmp/$_name');

  // Never reached: the renderer reads `name` and `readAsBytes()` only.
  // Left unimplemented rather than pulling in cross_file to satisfy a
  // getter nothing calls.
  @override
  get xFile => throw UnimplementedError();

  @override
  Future<int> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList(_bytes);

  @override
  Stream<Uint8List> readAsByteStream() =>
      Stream.value(Uint8List.fromList(_bytes));
}

/// Stands in for the real picker. `FilePicker`'s static methods delegate to
/// `FilePickerPlatform.instance`, which is settable — so the whole pick flow
/// is reachable without a production seam of our own.
///
/// `MockPlatformInterfaceMixin` is what gets it past the token check the
/// setter performs.
class _FakePicker extends FilePickerPlatform with MockPlatformInterfaceMixin {
  _FakePicker(this.returns);

  /// Queued results, one per pick. Lets a test pick twice with different
  /// files, which is the case single-file replacement is about.
  final List<List<PlatformFile>> returns;

  int pickCount = 0;
  final List<FileType> requestedTypes = [];

  List<PlatformFile> _next(FileType type) {
    requestedTypes.add(type);
    if (pickCount >= returns.length) return const [];
    return returns[pickCount++];
  }

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final result = _next(type);
    return result.isEmpty ? null : result.first;
  }

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => _next(type);
}

FileFieldSpec _spec({int? maxFiles, List<String>? accept}) => FileFieldSpec(
  name: 'car_images',
  label: 'Images',
  sizeHint: FieldSizeHint.medium,
  validation: FieldValidation(maxFiles: maxFiles, accept: accept),
);

void main() {
  late FilePickerPlatform original;

  setUp(() => original = FilePickerPlatform.instance);
  tearDown(() => FilePickerPlatform.instance = original);

  Future<FileValue?> pumpAndPick(
    WidgetTester tester, {
    required FileFieldSpec spec,
    required FileValue value,
    required _FakePicker picker,
  }) async {
    FilePickerPlatform.instance = picker;
    FieldValue? emitted;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FileFieldRenderer(
            spec: spec,
            value: value,
            error: null,
            onChanged: (v) => emitted = v,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    await tester.tap(find.text(AppLocalizations.of(context).actionPickFile));
    await tester.pumpAndSettle();

    return emitted as FileValue?;
  }

  testWidgets('a single-file field replaces through the real widget', (
    tester,
  ) async {
    final picker = _FakePicker([
      [_FakePlatformFile('second.png')],
    ]);

    final emitted = await pumpAndPick(
      tester,
      spec: _spec(maxFiles: 1),
      value: FileValue([
        SelectedFile(name: 'first.png', mimeType: 'image/png', bytes: const []),
      ]),
      picker: picker,
    );

    // Previously covered only through mergePickedFiles; this proves the
    // widget actually wires the pick to it.
    expect(emitted!.files.map((f) => f.name), ['second.png']);
  });

  testWidgets('a multi-file field appends through the real widget', (
    tester,
  ) async {
    final picker = _FakePicker([
      [_FakePlatformFile('b.png'), _FakePlatformFile('c.png')],
    ]);

    final emitted = await pumpAndPick(
      tester,
      spec: _spec(maxFiles: 10),
      value: FileValue([
        SelectedFile(name: 'a.png', mimeType: 'image/png', bytes: const []),
      ]),
      picker: picker,
    );

    expect(emitted!.files.map((f) => f.name), ['a.png', 'b.png', 'c.png']);
  });

  testWidgets('the picked file carries resolved bytes and mime type', (
    tester,
  ) async {
    final picker = _FakePicker([
      [
        _FakePlatformFile('photo.bmp', const [9, 9]),
      ],
    ]);

    final emitted = await pumpAndPick(
      tester,
      spec: _spec(maxFiles: 10),
      value: const FileValue([]),
      picker: picker,
    );

    final file = emitted!.files.single;
    // .bmp is exactly the format the old seven-entry table rejected.
    expect(file.mimeType, 'image/bmp');
    expect(file.bytes, [9, 9]);
    expect(file.sizeBytes, 2);
  });

  testWidgets('an image-only accept rule asks for the image picker', (
    tester,
  ) async {
    final picker = _FakePicker([
      [_FakePlatformFile('a.png')],
    ]);

    await pumpAndPick(
      tester,
      spec: _spec(maxFiles: 10, accept: const ['image/*']),
      value: const FileValue([]),
      picker: picker,
    );

    expect(picker.requestedTypes.single, FileType.image);
  });

  testWidgets('a mixed accept rule falls back to an unfiltered picker', (
    tester,
  ) async {
    final picker = _FakePicker([
      [_FakePlatformFile('a.pdf')],
    ]);

    await pumpAndPick(
      tester,
      spec: _spec(maxFiles: 10, accept: const ['image/*', 'application/pdf']),
      value: const FileValue([]),
      picker: picker,
    );

    expect(picker.requestedTypes.single, FileType.any);
  });

  testWidgets('cancelling the picker leaves the value untouched', (
    tester,
  ) async {
    final picker = _FakePicker([]); // every pick returns nothing

    final emitted = await pumpAndPick(
      tester,
      spec: _spec(maxFiles: 1),
      value: FileValue([
        SelectedFile(name: 'kept.png', mimeType: 'image/png', bytes: const []),
      ]),
      picker: picker,
    );

    expect(emitted, isNull, reason: 'onChanged should not fire on a cancel');
  });

  testWidgets('removing a chip drops just that file', (tester) async {
    FieldValue? emitted;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FileFieldRenderer(
            spec: _spec(maxFiles: 10),
            value: FileValue([
              SelectedFile(
                name: 'a.png',
                mimeType: 'image/png',
                bytes: const [],
              ),
              SelectedFile(
                name: 'b.png',
                mimeType: 'image/png',
                bytes: const [],
              ),
            ]),
            error: null,
            onChanged: (v) => emitted = v,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('a.png'), findsOneWidget);
    expect(find.text('b.png'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.cancel).first);
    await tester.pumpAndSettle();

    expect((emitted! as FileValue).files.map((f) => f.name), ['b.png']);
  });
}
