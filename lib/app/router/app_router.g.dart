// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $marketplaceRoute,
  $onboardingRoute,
  $authRoute,
  $legalRoute,
  $privacyRoute,
  $notificationSettingsRoute,
  $productDetailRoute,
  $sellerProfileRoute,
  $categoryProductsRoute,
  $mapRoute,
  $chatInboxRoute,
  $chatConversationRoute,
  $myListingsRoute,
  $moderationRoute,
  $publicProfileRoute,
  $editProfileRoute,
  $favoritesRoute,
  $recentlyViewedRoute,
  $businessStartRoute,
  $businessHubRoute,
  $businessDocumentsRoute,
  $businessProfileRoute,
  $businessHoursRoute,
  $businessMenuRoute,
];

RouteBase get $marketplaceRoute => GoRouteData.$route(
  path: '/',

  factory: $MarketplaceRouteExtension._fromState,
);

extension $MarketplaceRouteExtension on MarketplaceRoute {
  static MarketplaceRoute _fromState(GoRouterState state) => MarketplaceRoute(
    tab: _$convertMapValue('tab', state.uri.queryParameters, int.parse) ?? 0,
  );

  String get location => GoRouteData.$location(
    '/',
    queryParams: {if (tab != 0) 'tab': tab.toString()},
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

RouteBase get $onboardingRoute => GoRouteData.$route(
  path: '/onboarding',

  factory: $OnboardingRouteExtension._fromState,
);

extension $OnboardingRouteExtension on OnboardingRoute {
  static OnboardingRoute _fromState(GoRouterState state) =>
      const OnboardingRoute();

  String get location => GoRouteData.$location('/onboarding');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $authRoute =>
    GoRouteData.$route(path: '/auth', factory: $AuthRouteExtension._fromState);

extension $AuthRouteExtension on AuthRoute {
  static AuthRoute _fromState(GoRouterState state) => AuthRoute(
    register:
        _$convertMapValue(
          'register',
          state.uri.queryParameters,
          _$boolConverter,
        ) ??
        false,
    redirectTo: state.uri.queryParameters['redirect-to'],
  );

  String get location => GoRouteData.$location(
    '/auth',
    queryParams: {
      if (register != false) 'register': register.toString(),
      if (redirectTo != null) 'redirect-to': redirectTo,
    },
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

bool _$boolConverter(String value) {
  switch (value) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      throw UnsupportedError('Cannot convert "$value" into a bool.');
  }
}

RouteBase get $legalRoute => GoRouteData.$route(
  path: '/legal/:document',

  factory: $LegalRouteExtension._fromState,
);

extension $LegalRouteExtension on LegalRoute {
  static LegalRoute _fromState(GoRouterState state) =>
      LegalRoute(document: state.pathParameters['document']!);

  String get location =>
      GoRouteData.$location('/legal/${Uri.encodeComponent(document)}');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $privacyRoute => GoRouteData.$route(
  path: '/privacy',

  factory: $PrivacyRouteExtension._fromState,
);

extension $PrivacyRouteExtension on PrivacyRoute {
  static PrivacyRoute _fromState(GoRouterState state) => const PrivacyRoute();

  String get location => GoRouteData.$location('/privacy');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $notificationSettingsRoute => GoRouteData.$route(
  path: '/notifications',

  factory: $NotificationSettingsRouteExtension._fromState,
);

extension $NotificationSettingsRouteExtension on NotificationSettingsRoute {
  static NotificationSettingsRoute _fromState(GoRouterState state) =>
      const NotificationSettingsRoute();

  String get location => GoRouteData.$location('/notifications');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $productDetailRoute => GoRouteData.$route(
  path: '/products/:productId',

  factory: $ProductDetailRouteExtension._fromState,
);

extension $ProductDetailRouteExtension on ProductDetailRoute {
  static ProductDetailRoute _fromState(GoRouterState state) =>
      ProductDetailRoute(
        productId: state.pathParameters['productId']!,
        heroTag: state.uri.queryParameters['hero-tag'],
      );

  String get location => GoRouteData.$location(
    '/products/${Uri.encodeComponent(productId)}',
    queryParams: {if (heroTag != null) 'hero-tag': heroTag},
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $sellerProfileRoute => GoRouteData.$route(
  path: '/sellers/:sellerId',

  factory: $SellerProfileRouteExtension._fromState,
);

extension $SellerProfileRouteExtension on SellerProfileRoute {
  static SellerProfileRoute _fromState(GoRouterState state) =>
      SellerProfileRoute(sellerId: state.pathParameters['sellerId']!);

  String get location =>
      GoRouteData.$location('/sellers/${Uri.encodeComponent(sellerId)}');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $categoryProductsRoute => GoRouteData.$route(
  path: '/categories/:categoryId',

  factory: $CategoryProductsRouteExtension._fromState,
);

extension $CategoryProductsRouteExtension on CategoryProductsRoute {
  static CategoryProductsRoute _fromState(GoRouterState state) =>
      CategoryProductsRoute(categoryId: state.pathParameters['categoryId']!);

  String get location =>
      GoRouteData.$location('/categories/${Uri.encodeComponent(categoryId)}');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $mapRoute =>
    GoRouteData.$route(path: '/map', factory: $MapRouteExtension._fromState);

extension $MapRouteExtension on MapRoute {
  static MapRoute _fromState(GoRouterState state) =>
      MapRoute(categoryId: state.uri.queryParameters['category-id']);

  String get location => GoRouteData.$location(
    '/map',
    queryParams: {if (categoryId != null) 'category-id': categoryId},
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $chatInboxRoute => GoRouteData.$route(
  path: '/inbox',

  factory: $ChatInboxRouteExtension._fromState,
);

extension $ChatInboxRouteExtension on ChatInboxRoute {
  static ChatInboxRoute _fromState(GoRouterState state) =>
      const ChatInboxRoute();

  String get location => GoRouteData.$location('/inbox');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $chatConversationRoute => GoRouteData.$route(
  path: '/chat/:chatId',

  factory: $ChatConversationRouteExtension._fromState,
);

extension $ChatConversationRouteExtension on ChatConversationRoute {
  static ChatConversationRoute _fromState(GoRouterState state) =>
      ChatConversationRoute(chatId: state.pathParameters['chatId']!);

  String get location =>
      GoRouteData.$location('/chat/${Uri.encodeComponent(chatId)}');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $myListingsRoute => GoRouteData.$route(
  path: '/my-listings',

  factory: $MyListingsRouteExtension._fromState,
);

extension $MyListingsRouteExtension on MyListingsRoute {
  static MyListingsRoute _fromState(GoRouterState state) =>
      const MyListingsRoute();

  String get location => GoRouteData.$location('/my-listings');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $moderationRoute => GoRouteData.$route(
  path: '/moderation',

  factory: $ModerationRouteExtension._fromState,
);

extension $ModerationRouteExtension on ModerationRoute {
  static ModerationRoute _fromState(GoRouterState state) =>
      const ModerationRoute();

  String get location => GoRouteData.$location('/moderation');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $publicProfileRoute => GoRouteData.$route(
  path: '/profile/:username',

  factory: $PublicProfileRouteExtension._fromState,
);

extension $PublicProfileRouteExtension on PublicProfileRoute {
  static PublicProfileRoute _fromState(GoRouterState state) =>
      PublicProfileRoute(username: state.pathParameters['username']!);

  String get location =>
      GoRouteData.$location('/profile/${Uri.encodeComponent(username)}');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $editProfileRoute => GoRouteData.$route(
  path: '/edit-profile',

  factory: $EditProfileRouteExtension._fromState,
);

extension $EditProfileRouteExtension on EditProfileRoute {
  static EditProfileRoute _fromState(GoRouterState state) =>
      const EditProfileRoute();

  String get location => GoRouteData.$location('/edit-profile');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $favoritesRoute => GoRouteData.$route(
  path: '/favorites',

  factory: $FavoritesRouteExtension._fromState,
);

extension $FavoritesRouteExtension on FavoritesRoute {
  static FavoritesRoute _fromState(GoRouterState state) =>
      const FavoritesRoute();

  String get location => GoRouteData.$location('/favorites');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $recentlyViewedRoute => GoRouteData.$route(
  path: '/recently-viewed',

  factory: $RecentlyViewedRouteExtension._fromState,
);

extension $RecentlyViewedRouteExtension on RecentlyViewedRoute {
  static RecentlyViewedRoute _fromState(GoRouterState state) =>
      const RecentlyViewedRoute();

  String get location => GoRouteData.$location('/recently-viewed');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $businessStartRoute => GoRouteData.$route(
  path: '/business/start',

  factory: $BusinessStartRouteExtension._fromState,
);

extension $BusinessStartRouteExtension on BusinessStartRoute {
  static BusinessStartRoute _fromState(GoRouterState state) =>
      BusinessStartRoute(
        existingPrivateSellerId:
            state.uri.queryParameters['existing-private-seller-id'],
      );

  String get location => GoRouteData.$location(
    '/business/start',
    queryParams: {
      if (existingPrivateSellerId != null)
        'existing-private-seller-id': existingPrivateSellerId,
    },
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $businessHubRoute => GoRouteData.$route(
  path: '/business/:businessSellerId/overview',

  factory: $BusinessHubRouteExtension._fromState,
);

extension $BusinessHubRouteExtension on BusinessHubRoute {
  static BusinessHubRoute _fromState(GoRouterState state) => BusinessHubRoute(
    businessSellerId: state.pathParameters['businessSellerId']!,
  );

  String get location => GoRouteData.$location(
    '/business/${Uri.encodeComponent(businessSellerId)}/overview',
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $businessDocumentsRoute => GoRouteData.$route(
  path: '/business/:businessSellerId/documents',

  factory: $BusinessDocumentsRouteExtension._fromState,
);

extension $BusinessDocumentsRouteExtension on BusinessDocumentsRoute {
  static BusinessDocumentsRoute _fromState(GoRouterState state) =>
      BusinessDocumentsRoute(
        businessSellerId: state.pathParameters['businessSellerId']!,
      );

  String get location => GoRouteData.$location(
    '/business/${Uri.encodeComponent(businessSellerId)}/documents',
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $businessProfileRoute => GoRouteData.$route(
  path: '/business/:businessSellerId/profile',

  factory: $BusinessProfileRouteExtension._fromState,
);

extension $BusinessProfileRouteExtension on BusinessProfileRoute {
  static BusinessProfileRoute _fromState(GoRouterState state) =>
      BusinessProfileRoute(
        businessSellerId: state.pathParameters['businessSellerId']!,
      );

  String get location => GoRouteData.$location(
    '/business/${Uri.encodeComponent(businessSellerId)}/profile',
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $businessHoursRoute => GoRouteData.$route(
  path: '/business/:businessSellerId/hours',

  factory: $BusinessHoursRouteExtension._fromState,
);

extension $BusinessHoursRouteExtension on BusinessHoursRoute {
  static BusinessHoursRoute _fromState(GoRouterState state) =>
      BusinessHoursRoute(
        businessSellerId: state.pathParameters['businessSellerId']!,
      );

  String get location => GoRouteData.$location(
    '/business/${Uri.encodeComponent(businessSellerId)}/hours',
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $businessMenuRoute => GoRouteData.$route(
  path: '/business/:businessSellerId/menu',

  factory: $BusinessMenuRouteExtension._fromState,
);

extension $BusinessMenuRouteExtension on BusinessMenuRoute {
  static BusinessMenuRoute _fromState(GoRouterState state) => BusinessMenuRoute(
    businessSellerId: state.pathParameters['businessSellerId']!,
  );

  String get location => GoRouteData.$location(
    '/business/${Uri.encodeComponent(businessSellerId)}/menu',
  );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}
