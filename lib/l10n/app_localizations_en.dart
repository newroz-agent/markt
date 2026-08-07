// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Zêrîn';

  @override
  String get appTagline => 'Your marketplace. Exceptionally good.';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationCategories => 'Categories';

  @override
  String get navigationSell => 'Sell';

  @override
  String get navigationCart => 'Cart';

  @override
  String get navigationAccount => 'Profile';

  @override
  String get navigationFavorites => 'Favorites';

  @override
  String get navigationOrders => 'Orders';

  @override
  String get navigationMessages => 'Messages';

  @override
  String get navigationSettings => 'Settings';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionGetStarted => 'Get started';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDone => 'Done';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionSeeAll => 'See all';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionClearAll => 'Clear all';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionSignUp => 'Create account';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get stateErrorMessage => 'Please try again in a moment.';

  @override
  String get stateOfflineTitle => 'You’re offline';

  @override
  String get stateOfflineMessage =>
      'Check your internet connection and try again.';

  @override
  String get stateEmptyTitle => 'Nothing here yet';

  @override
  String get authRequiredTitle => 'Sign-in required';

  @override
  String get authRequiredMessage => 'Sign in to use this feature.';

  @override
  String get onboardingWelcomeTitle => 'Everything you love. In one place.';

  @override
  String get onboardingWelcomeBody =>
      'Discover curated products from shops and private sellers across Germany.';

  @override
  String get onboardingDiscoverTitle => 'Find something special nearby';

  @override
  String get onboardingDiscoverBody =>
      'Search, filter, and compare new and used items—safely and transparently.';

  @override
  String get onboardingSellTitle => 'Sell simply and safely';

  @override
  String get onboardingSellBody =>
      'List an item in minutes or build your own shop.';

  @override
  String get authWelcomeTitle => 'Welcome to Zêrîn';

  @override
  String get authWelcomeBody => 'Sign in to save favorites, shop, and sell.';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignInSubtitle => 'It’s good to have you back.';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authSignUpSubtitle => 'Create your account in just a few steps.';

  @override
  String get authDisplayNameLabel => 'Name';

  @override
  String get authDisplayNameHint => 'First and last name';

  @override
  String get authEmailLabel => 'Email address';

  @override
  String get authEmailHint => 'name@example.com';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authResetPasswordBody =>
      'We’ll send you a link to set a new password.';

  @override
  String get authSendResetLink => 'Send link';

  @override
  String get authResetLinkSent => 'The password reset link has been sent.';

  @override
  String get authNoAccount => 'Don’t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authOrSeparator => 'or';

  @override
  String get authTermsAgreement =>
      'By signing in, you agree to our Terms and Conditions and Privacy Policy.';

  @override
  String get authInvalidCredentials =>
      'The email address or password is incorrect.';

  @override
  String get authBackendNotConfigured =>
      'Authentication is not configured for this preview yet.';

  @override
  String get authEmailNotConfirmed =>
      'Please confirm your email address first.';

  @override
  String get authEmailAlreadyRegistered =>
      'An account already exists for this email address.';

  @override
  String get authWeakPassword =>
      'This password is too weak. Use at least 8 characters.';

  @override
  String get authNetworkError =>
      'The connection failed. Check your internet connection.';

  @override
  String get authUnknownError => 'Sign-in failed. Please try again.';

  @override
  String get authRegistrationCheckEmail =>
      'Account created. Check your inbox now to confirm your email address.';

  @override
  String get authEmailVerificationTitle => 'Confirm your email address';

  @override
  String authEmailVerificationBody({required String email}) {
    return 'We sent a confirmation link to $email.';
  }

  @override
  String get authResendVerification => 'Resend email';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationInvalidEmail => 'Enter a valid email address.';

  @override
  String validationPasswordMinLength({required int minLength}) {
    return 'The password must be at least $minLength characters long.';
  }

  @override
  String get validationPasswordMismatch => 'The passwords do not match.';

  @override
  String get homeGreeting => 'Hello!';

  @override
  String homeGreetingNamed({required String name}) {
    return 'Hello, $name!';
  }

  @override
  String get homeSearchHint => 'What are you looking for?';

  @override
  String get homeCategoriesTitle => 'Categories';

  @override
  String get homeDealsTitle => 'Deals & discounts';

  @override
  String get homeNewArrivalsTitle => 'New arrivals';

  @override
  String get homePopularNearbyTitle => 'Popular near you';

  @override
  String get homeRecentlyViewedTitle => 'Recently viewed';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesSearchHint => 'Search categories';

  @override
  String get categoriesEmptyTitle => 'No categories found';

  @override
  String get categoriesEmptyBody => 'Try a different search term.';

  @override
  String get sellTitle => 'Sell';

  @override
  String get sellPrivateTitle => 'Sell privately';

  @override
  String get sellPrivateBody => 'List your item in just a few minutes.';

  @override
  String get sellVendorTitle => 'Become a seller';

  @override
  String get sellVendorBody =>
      'Open your shop and reach customers across Germany.';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyBody => 'Discover products and add your favorites.';

  @override
  String cartItemCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartShipping => 'Shipping';

  @override
  String get cartVatIncluded => 'VAT included';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartCheckout => 'Go to checkout';

  @override
  String get accountTitle => 'Profile';

  @override
  String get accountProfile => 'Personal details';

  @override
  String get accountAddresses => 'Addresses';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountAppearance => 'Appearance';

  @override
  String get accountNotifications => 'Notifications';

  @override
  String get accountLegal => 'Legal';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountGuestTitle => 'Welcome to Zêrîn';

  @override
  String get accountGuestBody =>
      'Sign in to manage orders, favorites, and your sales.';

  @override
  String get foundationPreviewTitle => 'Your marketplace is taking shape';

  @override
  String get foundationPreviewBody =>
      'The design system, navigation, languages, and authentication are ready. More marketplace features are coming next.';

  @override
  String get languageGerman => 'German';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get themeSystem => 'System setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get productConditionNew => 'New';

  @override
  String get productConditionUsed => 'Used';

  @override
  String productVatIncluded({required String price}) {
    return '$price incl. VAT';
  }

  @override
  String get productFreeShipping => 'Free shipping';

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String get cartAdd => 'Add to cart';

  @override
  String resultsCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String semanticsSelectedTab({required String label}) {
    return '$label, selected';
  }

  @override
  String semanticsCartItemCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cart, $count items',
      one: 'Cart, 1 item',
      zero: 'Cart, no items',
    );
    return '$_temp0';
  }

  @override
  String get legalImprint => 'Legal notice';

  @override
  String get legalTerms => 'Terms and Conditions';

  @override
  String get legalPrivacy => 'Privacy Policy';

  @override
  String get legalWithdrawal => 'Right of withdrawal';

  @override
  String get legalComingSoonBody =>
      'The complete legal documents will be provided before release.';
}
