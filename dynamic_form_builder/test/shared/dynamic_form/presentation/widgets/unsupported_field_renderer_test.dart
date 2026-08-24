import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_size_hint.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_validation.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/field_value.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/domain/models/form_field_spec.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/field_widget_registry.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/unsupported_field_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _unsupported = UnsupportedFieldSpec(
  name: 'signature',
  label: 'Signature',
  rawType: 'signature_pad',
);

const _knownButUnrendered = TextFieldSpec(
  name: 'brand',
  label: 'Brand',
  validation: FieldValidation.none,
  sizeHint: FieldSizeHint.medium,
);

Widget _harness(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('an unknown wire type names the type the server sent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(const UnsupportedFieldRenderer(spec: _unsupported)),
    );

    expect(find.textContaining('signature_pad'), findsOneWidget);
  });

  testWidgets('a known spec with no renderer names its Dart type', (
    tester,
  ) async {
    // Can't synthesise the real case — FormFieldSpec is sealed, so a seventh
    // subtype can only be added in its own library. Passing a known spec
    // through the same constructor covers the path a missing registry entry
    // would take.
    await tester.pumpWidget(
      _harness(
        const UnsupportedFieldRenderer.forUnrendered(_knownButUnrendered),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('TextFieldSpec'), findsOneWidget);
  });

  testWidgets('the registry still renders an unknown wire type', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        FieldWidgetRegistry.build(
          spec: _unsupported,
          value: const TextValue(''),
          error: null,
          onChanged: (_) {},
          enabled: true,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('signature_pad'), findsOneWidget);
  });
}
