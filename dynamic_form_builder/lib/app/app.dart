import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dynamic_form_builder/core/design_system/theme/app_theme.dart';
import 'package:dynamic_form_builder/core/l10n/app_localizations.dart';
import 'package:dynamic_form_builder/shared/dynamic_form/presentation/widgets/dynamic_form_view.dart';

/// App root. `ProviderScope` is wired here since `DynamicFormView` reads
/// from it.
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
        home: const _HomePage(),
      ),
    );
  }
}

/// The one page in this repo. `dynamic_form` is a shared module, not a
/// feature with its own route (see the plan doc's `core`/`shared`/
/// `features` section) — this is the host a real subject page would
/// otherwise be, owning the `Scaffold`/`AppBar` while `DynamicFormView`
/// owns everything inside it.
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: const DynamicFormView(),
    );
  }
}
