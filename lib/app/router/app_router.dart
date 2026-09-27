import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/auth/presentation/auth_screen.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/business/presentation/business_documents_screen.dart';
import 'package:zerin_marketplace/features/business/presentation/business_hours_editor_screen.dart';
import 'package:zerin_marketplace/features/business/presentation/business_hub_screen.dart';
import 'package:zerin_marketplace/features/business/presentation/business_menu_editor_screen.dart';
import 'package:zerin_marketplace/features/business/presentation/business_profile_editor_screen.dart';
import 'package:zerin_marketplace/features/categories/presentation/category_products_screen.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_conversation_screen.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_inbox_screen.dart';
import 'package:zerin_marketplace/features/legal/presentation/legal_screen.dart';
import 'package:zerin_marketplace/features/map/presentation/map_screen.dart';
import 'package:zerin_marketplace/features/moderation/presentation/moderation_screen.dart';
import 'package:zerin_marketplace/features/onboarding/presentation/onboarding_screen.dart';
import 'package:zerin_marketplace/features/privacy/presentation/notification_settings_screen.dart';
import 'package:zerin_marketplace/features/privacy/presentation/privacy_screen.dart';
import 'package:zerin_marketplace/features/products/presentation/product_detail_screen.dart';
import 'package:zerin_marketplace/features/profile/presentation/edit_profile_screen.dart';
import 'package:zerin_marketplace/features/profile/presentation/favorites_screen.dart';
import 'package:zerin_marketplace/features/profile/presentation/public_profile_screen.dart';
import 'package:zerin_marketplace/features/profile/presentation/recently_viewed_screen.dart';
import 'package:zerin_marketplace/features/sell/presentation/my_listings_screen.dart';
import 'package:zerin_marketplace/features/sellers/presentation/seller_profile_screen.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/features/shell/presentation/marketplace_shell.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final chatRouteObserver = RouteObserver<ModalRoute<dynamic>>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final preferences = ref.read(sharedPreferencesProvider);
  final hasCompletedOnboarding =
      preferences.getBool(SettingsStorageKeys.onboardingComplete) ?? false;

  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => authRefresh.value++);
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    observers: <NavigatorObserver>[chatRouteObserver],
    refreshListenable: authRefresh,
    routes: $appRoutes,
    initialLocation: hasCompletedOnboarding ? '/' : '/onboarding',
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final isComplete =
          preferences.getBool(SettingsStorageKeys.onboardingComplete) ?? false;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isComplete && !isOnboarding) return '/onboarding';
      if (isComplete && isOnboarding) return '/';
      final isProtected =
          state.matchedLocation == '/inbox' ||
          state.matchedLocation.startsWith('/chat/') ||
          state.matchedLocation == '/my-listings' ||
          state.matchedLocation == '/edit-profile' ||
          state.matchedLocation == '/favorites' ||
          state.matchedLocation == '/recently-viewed' ||
          state.matchedLocation == '/moderation' ||
          state.matchedLocation == '/business' ||
          state.matchedLocation.startsWith('/business/');
      if (isProtected && ref.read(authRepositoryProvider).currentUser == null) {
        return AuthRoute(redirectTo: state.uri.toString()).location;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.route_outlined,
                size: AppSizes.iconState,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.stateErrorTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(context.l10n.stateErrorMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    authRefresh.dispose();
  });
  return router;
});

@TypedGoRoute<MarketplaceRoute>(path: '/')
class MarketplaceRoute extends GoRouteData {
  const MarketplaceRoute({this.tab = 0});

  final int tab;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MarketplaceShell(initialIndex: tab);
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData {
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const OnboardingScreen();
}

@TypedGoRoute<AuthRoute>(path: '/auth')
class AuthRoute extends GoRouteData {
  const AuthRoute({this.register = false, this.redirectTo});

  final bool register;
  final String? redirectTo;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AuthScreen(initialRegister: register, redirectLocation: redirectTo);
}

@TypedGoRoute<LegalRoute>(path: '/legal/:document')
class LegalRoute extends GoRouteData {
  const LegalRoute({required this.document});

  final String document;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LegalScreen(document: document);
}

@TypedGoRoute<PrivacyRoute>(path: '/privacy')
class PrivacyRoute extends GoRouteData {
  const PrivacyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrivacyScreen();
}

@TypedGoRoute<NotificationSettingsRoute>(path: '/notifications')
class NotificationSettingsRoute extends GoRouteData {
  const NotificationSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationSettingsScreen();
}

@TypedGoRoute<ProductDetailRoute>(path: '/products/:productId')
class ProductDetailRoute extends GoRouteData {
  const ProductDetailRoute({required this.productId, this.heroTag});

  final String productId;
  final String? heroTag;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProductDetailScreen(productId: productId, heroTag: heroTag);
}

@TypedGoRoute<SellerProfileRoute>(path: '/sellers/:sellerId')
class SellerProfileRoute extends GoRouteData {
  const SellerProfileRoute({required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SellerProfileScreen(sellerId: sellerId);
}

@TypedGoRoute<CategoryProductsRoute>(path: '/categories/:categoryId')
class CategoryProductsRoute extends GoRouteData {
  const CategoryProductsRoute({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CategoryProductsScreen(categoryId: categoryId);
}

@TypedGoRoute<MapRoute>(path: '/map')
class MapRoute extends GoRouteData {
  const MapRoute({this.categoryId});

  final String? categoryId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MapScreen(initialCategoryId: categoryId);
}

@TypedGoRoute<ChatInboxRoute>(path: '/inbox')
class ChatInboxRoute extends GoRouteData {
  const ChatInboxRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ChatInboxScreen();
}

@TypedGoRoute<ChatConversationRoute>(path: '/chat/:chatId')
class ChatConversationRoute extends GoRouteData {
  const ChatConversationRoute({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ChatConversationScreen(chatId: chatId);
}

@TypedGoRoute<MyListingsRoute>(path: '/my-listings')
class MyListingsRoute extends GoRouteData {
  const MyListingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MyListingsScreen();
}

@TypedGoRoute<ModerationRoute>(path: '/moderation')
class ModerationRoute extends GoRouteData {
  const ModerationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ModerationScreen();
}

@TypedGoRoute<PublicProfileRoute>(path: '/profile/:username')
class PublicProfileRoute extends GoRouteData {
  const PublicProfileRoute({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PublicProfileScreen(username: username);
}

@TypedGoRoute<EditProfileRoute>(path: '/edit-profile')
class EditProfileRoute extends GoRouteData {
  const EditProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const EditProfileScreen();
}

@TypedGoRoute<FavoritesRoute>(path: '/favorites')
class FavoritesRoute extends GoRouteData {
  const FavoritesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const FavoritesScreen();
}

@TypedGoRoute<RecentlyViewedRoute>(path: '/recently-viewed')
class RecentlyViewedRoute extends GoRouteData {
  const RecentlyViewedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RecentlyViewedScreen();
}

@TypedGoRoute<BusinessHubRoute>(path: '/business')
class BusinessHubRoute extends GoRouteData {
  const BusinessHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BusinessHubScreen();
}

@TypedGoRoute<BusinessDocumentsRoute>(path: '/business/documents')
class BusinessDocumentsRoute extends GoRouteData {
  const BusinessDocumentsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BusinessDocumentsScreen();
}

@TypedGoRoute<BusinessProfileRoute>(path: '/business/profile')
class BusinessProfileRoute extends GoRouteData {
  const BusinessProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BusinessProfileEditorScreen();
}

@TypedGoRoute<BusinessHoursRoute>(path: '/business/hours')
class BusinessHoursRoute extends GoRouteData {
  const BusinessHoursRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BusinessHoursEditorScreen();
}

@TypedGoRoute<BusinessMenuRoute>(path: '/business/menu')
class BusinessMenuRoute extends GoRouteData {
  const BusinessMenuRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BusinessMenuEditorScreen();
}
