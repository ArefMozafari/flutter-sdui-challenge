import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/file_field_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

SelectedFile _file(String name) =>
    SelectedFile(name: name, mimeType: 'image/png', bytes: const [1, 2, 3]);

void main() {
  group('mergePickedFiles', () {
    test('a single-file field replaces what it already held', () {
      // Pick, change your mind, pick again. Appending here left two files on
      // a field that allows one, which submit then rejected.
      final merged = mergePickedFiles(
        existing: [_file('first.png')],
        picked: [_file('second.png')],
        maxFiles: 1,
      );

      expect(merged.map((f) => f.name), ['second.png']);
    });

    test('a single-file field starts from empty just as well', () {
      final merged = mergePickedFiles(
        existing: const [],
        picked: [_file('only.png')],
        maxFiles: 1,
      );

      expect(merged.map((f) => f.name), ['only.png']);
    });

    test('a multi-file field appends', () {
      final merged = mergePickedFiles(
        existing: [_file('first.png')],
        picked: [_file('second.png'), _file('third.png')],
        maxFiles: 10,
      );

      expect(merged.map((f) => f.name), [
        'first.png',
        'second.png',
        'third.png',
      ]);
    });

    test('an unbounded field appends', () {
      final merged = mergePickedFiles(
        existing: [_file('first.png')],
        picked: [_file('second.png')],
        maxFiles: null,
      );

      expect(merged.map((f) => f.name), ['first.png', 'second.png']);
    });

    test(
      'overflowing a multi-file field is left to submit-time validation',
      () {
        // Deliberately not capped here — the user chose these and can remove
        // one; validateField reports it. Only the single-file case is special.
        final merged = mergePickedFiles(
          existing: [_file('a.png'), _file('b.png')],
          picked: [_file('c.png')],
          maxFiles: 2,
        );

        expect(merged, hasLength(3));
      },
    );
  });
}
