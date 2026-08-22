import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/theme/app_theme.dart';
import '../core/l10n/app_localizations.dart';

/// App root. `ProviderScope` is wired here even though no feature reads a
/// provider yet — the dynamic-form feature (added on top of this branch)
/// depends on it existing, and there's nothing else that should own it.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.light(),
        locale: const Locale('fa'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _AppShellPlaceholder(),
      ),
    );
  }
}

/// Stands in for `DynamicFormPage` until the presentation layer lands
/// (branch `feat/application-presentation`) — proves the theme, RTL layout,
/// and localization delegates are wired correctly before any form code
/// depends on them.
class _AppShellPlaceholder extends StatelessWidget {
  const _AppShellPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(child: Text(l10n.stateLoading)),
    );
  }
}
