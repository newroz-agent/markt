import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/legal/domain/legal_document.dart';
import 'package:zerin_marketplace/features/settings/domain/app_settings.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final authState = ref.watch(authStateProvider);
    final settings =
        ref.watch(appSettingsControllerProvider).asData?.value ??
        const AppSettings();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              authState.when(
                data: (user) => _AccountHeader(user: user),
                loading: () =>
                    const AppSkeletonBox(height: AppSizes.stateIllustration),
                error: (_, _) => AppErrorState(
                  title: l10n.stateErrorTitle,
                  message: l10n.stateErrorMessage,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: Text(l10n.accountLanguage),
                      subtitle: Text(
                        Locale(settings.localeCode).localizedDisplayName(l10n),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showLanguageSheet(context, ref),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.contrast_rounded),
                      title: Text(l10n.accountAppearance),
                      subtitle: Text(
                        _themeLabel(l10n, settings.themePreference),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showThemeSheet(context, ref),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: Text(l10n.accountNotifications),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          const NotificationSettingsRoute().push<void>(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l10n.accountPrivacy),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => const PrivacyRoute().push<void>(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.accountLegal,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Column(
                  children: <Widget>[
                    _LegalTile(
                      icon: Icons.business_outlined,
                      label: l10n.legalImprint,
                      slug: LegalDocumentSlugs.imprint,
                    ),
                    const Divider(),
                    _LegalTile(
                      icon: Icons.description_outlined,
                      label: l10n.legalTerms,
                      slug: LegalDocumentSlugs.terms,
                    ),
                    const Divider(),
                    _LegalTile(
                      icon: Icons.shield_outlined,
                      label: l10n.legalPrivacy,
                      slug: LegalDocumentSlugs.privacy,
                    ),
                    const Divider(),
                    _LegalTile(
                      icon: Icons.assignment_return_outlined,
                      label: l10n.legalWithdrawal,
                      slug: LegalDocumentSlugs.withdrawal,
                    ),
                  ],
                ),
              ),
              if (authState.asData?.value != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                AppButton.destructive(
                  label: l10n.accountDelete,
                  leading: const Icon(Icons.delete_outline_rounded),
                  // Deletion lives on the privacy screen, next to the export
                  // and the cancel affordance the DSGVO flow depends on.
                  onPressed: () => const PrivacyRoute().push<void>(context),
                  expand: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _themeLabel(
    AppLocalizations l10n,
    AppThemePreference preference,
  ) => switch (preference) {
    AppThemePreference.system => l10n.themeSystem,
    AppThemePreference.light => l10n.themeLight,
    AppThemePreference.dark => l10n.themeDark,
  };

  static Future<void> _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentCode =
        ref.read(appSettingsControllerProvider).asData?.value.localeCode ??
        'de';
    await showAppBottomSheet<void>(
      context: context,
      title: context.l10n.accountLanguage,
      child: Column(
        children: <Widget>[
          for (final locale in AppLocale.supportedLocales)
            ListTile(
              title: Text(locale.localizedDisplayName(context.l10n)),
              trailing: locale.languageCode == currentCode
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () async {
                await ref
                    .read(appSettingsControllerProvider.notifier)
                    .setLocale(locale.languageCode);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  static Future<void> _showThemeSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current =
        ref.read(appSettingsControllerProvider).asData?.value.themePreference ??
        AppThemePreference.system;
    await showAppBottomSheet<void>(
      context: context,
      title: context.l10n.accountAppearance,
      child: Column(
        children: <Widget>[
          for (final preference in AppThemePreference.values)
            ListTile(
              title: Text(_themeLabel(context.l10n, preference)),
              trailing: preference == current
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () async {
                await ref
                    .read(appSettingsControllerProvider.notifier)
                    .setTheme(preference);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _AccountHeader extends ConsumerWidget {
  const _AccountHeader({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final authAction = ref.watch(authControllerProvider);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: AppSizes.stateIllustration,
                  height: AppSizes.stateIllustration,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user == null ? Icons.person_outline : Icons.person_rounded,
                    size: AppSizes.iconState,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.displayName ?? l10n.accountGuestTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        user?.email ?? l10n.accountGuestBody,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (user == null)
              AppButton.primary(
                label: l10n.actionSignIn,
                onPressed: () => const AuthRoute().push<void>(context),
                expand: true,
              )
            else
              AppButton.ghost(
                label: l10n.actionSignOut,
                leading: const Icon(Icons.logout_rounded),
                loading: authAction.isLoading,
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted &&
                      ref.read(authControllerProvider).hasError) {
                    AppSnackBar.show(
                      context,
                      message: l10n.stateErrorMessage,
                      variant: AppSnackBarVariant.error,
                    );
                  }
                },
                expand: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.icon,
    required this.label,
    required this.slug,
  });

  final IconData icon;
  final String label;
  final String slug;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => LegalRoute(document: slug).push<void>(context),
  );
}
