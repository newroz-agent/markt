import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/settings/domain/app_settings.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class ZerinApp extends ConsumerWidget {
  const ZerinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsControllerProvider).asData?.value ??
        const AppSettings();
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appName,
      locale: AppLocale.normalize(Locale(settings.localeCode)),
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (settings.themePreference) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      },
      routerConfig: router,
    );
  }
}
