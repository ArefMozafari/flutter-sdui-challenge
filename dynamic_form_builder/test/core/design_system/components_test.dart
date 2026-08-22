import 'package:dynamic_form_builder/core/design_system/components/ds_button.dart';
import 'package:dynamic_form_builder/core/design_system/components/ds_field_label.dart';
import 'package:dynamic_form_builder/core/design_system/components/ds_file_picker.dart';
import 'package:dynamic_form_builder/core/design_system/components/ds_select.dart';
import 'package:dynamic_form_builder/core/design_system/components/ds_text_field.dart';
import 'package:dynamic_form_builder/core/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  group('DsFieldLabel', () {
    testWidgets('shows a required marker only when asked', (tester) async {
      await tester.pumpWidget(_wrap(const DsFieldLabel('Brand', isRequired: true)));
      expect(find.textContaining('Brand'), findsOneWidget);
      expect(find.textContaining('*'), findsOneWidget);

      await tester.pumpWidget(_wrap(const DsFieldLabel('Brand')));
      expect(find.textContaining('*'), findsNothing);
    });
  });

  group('DsTextField', () {
    testWidgets('reports typed text and keeps its own cursor across rebuilds', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(_wrap(DsTextField(label: 'Brand', onChanged: changes.add)));

      await tester.enterText(find.byType(TextFormField), 'Toyota');
      expect(changes, ['Toyota']);

      // Rebuilding the parent (as a Riverpod rebuild on an unrelated field
      // would) must not reset what the user already typed.
      await tester.pumpWidget(_wrap(DsTextField(label: 'Brand', onChanged: changes.add)));
      expect(find.text('Toyota'), findsOneWidget);
    });

    testWidgets('surfaces an external error message', (tester) async {
      await tester.pumpWidget(
        _wrap(DsTextField(label: 'Brand', errorText: 'Required', onChanged: (_) {})),
      );
      expect(find.text('Required'), findsOneWidget);
    });
  });

  group('DsSelect', () {
    testWidgets('reports the chosen option value, not its label', (tester) async {
      String? picked;
      await tester.pumpWidget(_wrap(DsSelect<String>(
        label: 'Fuel',
        options: const [
          DsSelectOption(label: 'Gasoline', value: 'gasoline'),
          DsSelectOption(label: 'Diesel', value: 'diesel'),
        ],
        onChanged: (value) => picked = value,
      )));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diesel').last);
      await tester.pumpAndSettle();

      expect(picked, 'diesel');
    });
  });

  group('DsFilePicker', () {
    testWidgets('renders one chip per selected file and reports pick taps', (tester) async {
      var pickRequested = false;
      await tester.pumpWidget(_wrap(DsFilePicker(
        label: 'Photos',
        fileNames: const ['a.jpg', 'b.jpg'],
        pickButtonLabel: 'Choose file',
        onPickRequested: () => pickRequested = true,
      )));

      expect(find.byType(Chip), findsNWidgets(2));
      await tester.tap(find.text('Choose file'));
      expect(pickRequested, isTrue);
    });

    testWidgets('reports which file was removed', (tester) async {
      int? removedIndex;
      await tester.pumpWidget(_wrap(DsFilePicker(
        label: 'Photos',
        fileNames: const ['a.jpg', 'b.jpg'],
        pickButtonLabel: 'Choose file',
        onPickRequested: () {},
        onRemove: (index) => removedIndex = index,
      )));

      await tester.tap(find.byIcon(Icons.cancel).first);
      expect(removedIndex, isNotNull);
    });
  });

  group('DsButton', () {
    testWidgets('shows a spinner and ignores taps while loading', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(DsButton(label: 'Submit', isLoading: true, onPressed: () => pressed = true)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);

      await tester.tap(find.byType(FilledButton));
      expect(pressed, isFalse);
    });
  });
}
