import 'package:dynamic_form_builder/app/app.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots with the Farsi title and RTL layout by default', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.appTitle), findsOneWidget);
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
