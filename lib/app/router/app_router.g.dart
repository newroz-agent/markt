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
      ProductDetailRoute(productId: state.pathParameters['productId']!);

  String get location =>
      GoRouteData.$location('/products/${Uri.encodeComponent(productId)}');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}
