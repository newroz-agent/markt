import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class _SignedOutAuthRepository implements AuthRepository {
  const _SignedOutAuthRepository();

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get authStateChanges => Stream<AuthUser?>.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('typed profile routes generate canonical encoded locations', () {
    expect(
      const PublicProfileRoute(username: 'alice_name').location,
      '/profile/alice_name',
    );
    expect(
      const PublicProfileRoute(username: 'name/segment').location,
      '/profile/name%2Fsegment',
    );
    expect(const EditProfileRoute().location, '/edit-profile');
    expect(const FavoritesRoute().location, '/favorites');
    expect(const RecentlyViewedRoute().location, '/recently-viewed');
  });

  testWidgets(
    'public profile stays public while edit profile preserves return URL',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SettingsStorageKeys.onboardingComplete: true,
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          authRepositoryProvider.overrideWithValue(
            const _SignedOutAuthRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: AppLocale.english,
            supportedLocales: AppLocale.supportedLocales,
            localizationsDelegates: AppLocale.localizationsDelegates,
          ),
        ),
      );

      router.go(const PublicProfileRoute(username: 'alice_name').location);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/profile/alice_name',
      );

      router.go(const EditProfileRoute().location);
      await tester.pumpAndSettle();
      final uri = router.routeInformationProvider.value.uri;
      expect(uri.path, '/auth');
      expect(uri.queryParameters['redirect-to'], '/edit-profile');
    },
  );
}
