import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/components/ds_button.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/failures/failure.dart';
import '../controllers/dynamic_form_controller.dart';
import '../states/dynamic_form_view_state.dart';
import 'failure_message_resolver.dart';
import 'field_widget_registry.dart';

/// The composable content of `dynamic_form` — not a `Page`. It has no
/// `Scaffold`, no `AppBar`, no route of its own: whoever hosts it (a
/// subject page, in the real Survey App this challenge stands in for)
/// owns that chrome, same as any other embedded content. In this repo,
/// `app/app.dart`'s home page is that host. See the plan doc's
/// `core`/`shared`/`features` section for why.
class DynamicFormView extends ConsumerWidget {
  const DynamicFormView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dynamicFormControllerProvider);
    final l10n = AppLocalizations.of(context);

    return switch (state) {
      DynamicFormLoading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.stateLoading),
          ],
        ),
      ),
      DynamicFormLoadError(:final failure) => _LoadErrorView(failure: failure),
      DynamicFormLoaded() => _LoadedView(state: state),
    };
  }
}

class _LoadErrorView extends ConsumerWidget {
  const _LoadErrorView({required this.failure});
  final Failure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resolveFailureMessage(l10n, failure),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            DsButton(
              label: l10n.actionRetry,
              onPressed: () =>
                  ref.read(dynamicFormControllerProvider.notifier).retryLoad(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends ConsumerWidget {
  const _LoadedView({required this.state});
  final DynamicFormLoaded state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(dynamicFormControllerProvider.notifier);

    return Column(
      children: [
        if (state.submitFailure != null)
          _Banner(
            text: resolveFailureMessage(l10n, state.submitFailure!),
            background: Theme.of(context).colorScheme.errorContainer,
            foreground: Theme.of(context).colorScheme.onErrorContainer,
          ),
        if (state.submitSucceeded)
          _Banner(
            text: l10n.stateSubmitSuccess,
            background: AppColors.success,
            foreground: AppColors.onSuccess,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final field in state.spec.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: FieldWidgetRegistry.build(
                    field,
                    state.values[field.name]!,
                    state.fieldErrors[field.name],
                    (value) => notifier.updateValue(field.name, value),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: DsButton(
            label: l10n.actionSubmit,
            isLoading: state.isSubmitting,
            onPressed: notifier.submit,
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(text, style: TextStyle(color: foreground)),
    );
  }
}
