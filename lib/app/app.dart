import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';
import 'package:zerin_marketplace/features/settings/domain/app_settings.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// The app-wide snackbar host (every [AppSnackBar] lands here).
final appScaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>(
      (ref) => GlobalKey<ScaffoldMessengerState>(debugLabel: 'app-messenger'),
    );

class ZerinApp extends ConsumerWidget {
  const ZerinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsControllerProvider).asData?.value ??
        const AppSettings();
    final router = ref.watch(appRouterProvider);
    final messengerKey = ref.watch(appScaffoldMessengerKeyProvider);
    // Eagerly fetches the current user's server catalog and validates the
    // UID-scoped device preference on every app/session start.
    ref.watch(activeIdentityControllerProvider);
    // A message meant for one account must never be shown to the next one:
    // clear every snackbar on sign-in, sign-out and account switch.
    ref.listen(authStateProvider.select((state) => state.valueOrNull?.id), (
      previous,
      next,
    ) {
      if (previous != next) messengerKey.currentState?.clearSnackBars();
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appName,
      locale: AppLocale.normalize(Locale(settings.localeCode)),
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: AppLocale.localizationsDelegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (settings.themePreference) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      },
      scaffoldMessengerKey: messengerKey,
      routerConfig: router,
    );
  }
}
