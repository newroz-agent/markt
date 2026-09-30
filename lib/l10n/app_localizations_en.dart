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
  String get homeAllCategoriesLabel => 'All';

  @override
  String get homeDealsTitle => 'Offers';

  @override
  String get homeNewArrivalsTitle => 'New arrivals';

  @override
  String get homePopularStoresTitle => 'Popular stores';

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
  String get accountSellingProfilesTitle => 'Your selling profiles';

  @override
  String get accountPersonalIdentity => 'Private person';

  @override
  String get accountRegisterBusiness => 'Register a business';

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
  String get languageKurdish => 'Kurdî';

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
  String get legalDataSources => 'Data sources';

  @override
  String get legalOsmAttribution =>
      'Map and place data © OpenStreetMap contributors, licensed under the Open Database License (ODbL).';

  @override
  String get directoryUnverifiedOsmNote =>
      'Not verified · Data © OpenStreetMap contributors';

  @override
  String get legalComingSoonBody =>
      'The complete legal documents will be provided before release.';

  @override
  String get legalUnknownDocumentBody => 'This legal document does not exist.';

  @override
  String get legalLoadErrorTitle => 'Document not loaded';

  @override
  String get legalLoadErrorBody =>
      'The text could not be retrieved. Check your internet connection.';

  @override
  String legalVersionLine({required String version, required String date}) {
    return 'Version $version · effective $date';
  }

  @override
  String get legalLinkFailed => 'The link could not be opened.';

  @override
  String get accountPrivacy => 'Privacy & data';

  @override
  String get privacyTitle => 'Privacy & data';

  @override
  String get privacySignedOutTitle => 'Sign in';

  @override
  String get privacySignedOutBody =>
      'Your privacy settings belong to your account.';

  @override
  String get privacyAnalyticsTitle => 'Allow analytics';

  @override
  String get privacyAnalyticsBody =>
      'Helps us find bugs and improve the app. You can withdraw this at any time.';

  @override
  String privacyAnalyticsGrantedAt({required String date}) {
    return 'Granted on $date';
  }

  @override
  String get privacyDataSectionTitle => 'Your data';

  @override
  String get privacyExportTitle => 'Export data';

  @override
  String get privacyExportBody =>
      'We prepare a copy of your data for download.';

  @override
  String get privacyExportRequest => 'Request export';

  @override
  String get privacyExportPending =>
      'Your export is being prepared. We will notify you once it is ready.';

  @override
  String get privacyExportReady => 'Your export is ready.';

  @override
  String get privacyExportExpired =>
      'This export has expired. Request a new one.';

  @override
  String get privacyExportDownload => 'Download';

  @override
  String get privacyExportRequested => 'Export requested.';

  @override
  String get privacyDeleteTitle => 'Delete account';

  @override
  String get privacyDeleteBody =>
      'Deletes your account and personal data. Orders are retained for tax reasons.';

  @override
  String get privacyDeleteConfirmTitle => 'Delete your account?';

  @override
  String privacyDeleteConfirmBody({required String word}) {
    return 'Type $word to confirm. You can still cancel the deletion as long as it has not been processed.';
  }

  @override
  String get privacyDeleteConfirmLabel => 'Confirmation';

  @override
  String get privacyDeletePending =>
      'Your deletion is requested. You can still cancel it.';

  @override
  String get privacyDeleteProcessing =>
      'Your deletion is being processed and can no longer be cancelled.';

  @override
  String get privacyDeleteRequested => 'Deletion requested.';

  @override
  String get privacyDeleteCancel => 'Cancel deletion';

  @override
  String get privacyDeleteCancelled => 'Deletion cancelled.';

  @override
  String get privacyDeleteCancelFailed =>
      'The deletion is already being processed and can no longer be cancelled.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsBody => 'Choose what we may notify you about.';

  @override
  String get notificationsOrders => 'Orders';

  @override
  String get notificationsOrdersBody => 'Payment, shipping and delivery.';

  @override
  String get notificationsChat => 'Messages';

  @override
  String get notificationsChatBody => 'New messages from buyers and sellers.';

  @override
  String get notificationsOffers => 'Offers';

  @override
  String get notificationsOffersBody =>
      'Promotions and recommendations. Off by default.';

  @override
  String get notificationsPriceDrops => 'Price alerts';

  @override
  String get notificationsPriceDropsBody => 'When a favourite gets cheaper.';

  @override
  String get notificationsSystem => 'System';

  @override
  String get notificationsSystemBody =>
      'Security and important account notices.';

  @override
  String get notificationsSaveFailed => 'The setting could not be saved.';

  @override
  String get notificationsSignedOutTitle => 'Sign in';

  @override
  String get notificationsSignedOutBody =>
      'Your notifications belong to your account.';

  @override
  String get categoryProductsAll => 'All';

  @override
  String get categoryProductsEmptyTitle => 'No listings';

  @override
  String get categoryProductsEmptyBody =>
      'There are no matching listings in this category yet.';

  @override
  String get filterConditionLabel => 'Condition';

  @override
  String get filterConditionAll => 'All';

  @override
  String get filterSortLabel => 'Sort order';

  @override
  String get filterSortNewest => 'Newest';

  @override
  String get filterSortPriceAsc => 'Price: low to high';

  @override
  String get filterSortPriceDesc => 'Price: high to low';

  @override
  String get filterSellerKindLabel => 'Seller type';

  @override
  String get filterSellerKindAll => 'All';

  @override
  String get filterSellerKindPrivate => 'Private';

  @override
  String get filterSellerKindBusiness => 'Business';

  @override
  String get filterCityLabel => 'City';

  @override
  String get filterCityAll => 'Everywhere';

  @override
  String get filterCityTitle => 'Choose a city';

  @override
  String get categoryViewGrid => 'Grid';

  @override
  String get categoryViewList => 'List';

  @override
  String get categorySearchInCategory => 'Search in this category';

  @override
  String get categoryProductsLoadMore => 'Load more';

  @override
  String get categoryProductsNoMore => 'No more listings';

  @override
  String get productContactSeller => 'Contact seller';

  @override
  String get chatInboxTitle => 'Messages';

  @override
  String get chatInboxEmptyTitle => 'No messages yet';

  @override
  String get chatInboxEmptyBody =>
      'Your conversations with buyers and sellers will appear here.';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatTitle => 'Conversation';

  @override
  String get chatProductCard => 'Product';

  @override
  String get chatInputHint => 'Write a message …';

  @override
  String get chatSend => 'Send message';

  @override
  String get chatLoadEarlier => 'Load earlier messages';

  @override
  String get productActionsLabel => 'Product actions';

  @override
  String get productShare => 'Share';

  @override
  String productShareText({required String title, required String price}) {
    return '$title – $price on DÛKAN';
  }

  @override
  String get productReport => 'Report listing';

  @override
  String get productReportTitle => 'Why are you reporting this listing?';

  @override
  String get productReportDetailsHint =>
      'Optional details (max 3000 characters)';

  @override
  String get productReportSubmit => 'Send report';

  @override
  String get productReportSubmitted => 'Thank you. We will review your report.';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonFraud => 'Fraud';

  @override
  String get reportReasonCounterfeit => 'Counterfeit';

  @override
  String get reportReasonProhibited => 'Prohibited item';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get sellerVerified => 'Verified';

  @override
  String get sellerTypePrivate => 'Private';

  @override
  String get sellerTypeBusiness => 'Business';

  @override
  String get sellerProfileListingsTitle => 'Listings from this seller';

  @override
  String get sellerProfileAbout => 'About';

  @override
  String get sellerProfileNoBio =>
      'This seller has not added a description yet.';

  @override
  String get sellerProfileEmptyListings => 'No listings available right now.';

  @override
  String get sellerProfileLoadFailed => 'Seller not found.';

  @override
  String get productSimilarTitle => 'Similar listings';

  @override
  String get productSimilarEmpty => 'No similar listings yet.';

  @override
  String get productSellerListingsTitle => 'More from this seller';

  @override
  String get productDetailsTitle => 'Product details';

  @override
  String get productDetailsCondition => 'Condition';

  @override
  String get productDetailsCategory => 'Category';

  @override
  String get productDetailsCity => 'City';

  @override
  String get productDetailsShipping => 'Shipping';

  @override
  String get productDetailsFreeShipping => 'Free shipping';

  @override
  String get productDetailsPaidShipping => 'Seller ships';

  @override
  String get productDetailsPickupOnly => 'Pickup only';

  @override
  String get productDescriptionMore => 'Show more';

  @override
  String get productDescriptionLess => 'Show less';

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get favoriteRemoved => 'Removed from favorites';

  @override
  String get viewSellerProfile => 'View seller profile';

  @override
  String get productUnavailableTitle => 'Listing unavailable';

  @override
  String get productUnavailableBody =>
      'This listing cannot be displayed right now.';

  @override
  String get productImageUnavailable => 'Image unavailable';

  @override
  String productGalleryPosition({required int current, required int total}) {
    return 'Image $current of $total';
  }

  @override
  String get productDetailsBrand => 'Brand';

  @override
  String get productShippingArrangement =>
      'Arrange shipping directly with the seller.';

  @override
  String get favoriteAddAction => 'Add to favorites';

  @override
  String get favoriteRemoveAction => 'Remove from favorites';

  @override
  String get sellCatalogTitle => 'What would you like to sell?';

  @override
  String get sellCatalogBody =>
      'Search for a similar item first, or start without a template.';

  @override
  String get sellCatalogSearchHint => 'Search catalog';

  @override
  String get sellCatalogUseTemplate => 'Use template';

  @override
  String get sellFreeForm => 'Start without template';

  @override
  String get sellNoTemplatesTitle => 'No matching template';

  @override
  String get sellNoTemplatesBody => 'You can enter your listing from scratch.';

  @override
  String get sellDetailsTitle => 'Listing details';

  @override
  String get sellSellerKindLabel => 'Seller type';

  @override
  String get sellSellerPrivate => 'Private';

  @override
  String get sellSellerBusiness => 'Business';

  @override
  String get sellSellerNameLabel => 'Display name';

  @override
  String get sellListingTitleLabel => 'Title';

  @override
  String get sellPriceLabel => 'Price in euros';

  @override
  String get sellCityLabel => 'City';

  @override
  String get sellCategoryLabel => 'Category';

  @override
  String get sellConditionLabel => 'Condition';

  @override
  String get sellDescriptionLabel => 'Description';

  @override
  String get sellPhotosTitle => 'Photos';

  @override
  String get sellPhotosBody =>
      'Add 1 to 10 photos. Images are compressed before upload.';

  @override
  String get sellPickPhotos => 'Choose photos';

  @override
  String get sellTakePhoto => 'Take photo';

  @override
  String get sellPhotoLimit => 'Maximum 10 photos';

  @override
  String get sellPhotoFailed => 'The photo could not be processed.';

  @override
  String get sellReviewTitle => 'Review and submit';

  @override
  String get sellSubmit => 'Submit for review';

  @override
  String get sellValidationRequired => 'This field is required.';

  @override
  String get sellValidationPrice => 'Enter a valid price greater than 0.';

  @override
  String get sellValidationDescription =>
      'The description must have at least 10 characters.';

  @override
  String get sellValidationPhotos => 'Add at least one photo.';

  @override
  String get sellConfirmationTitle => 'Listing under review';

  @override
  String get sellConfirmationBody =>
      'Your listing was submitted and is not public yet. We will notify you after review.';

  @override
  String get sellViewMyListings => 'View my listings';

  @override
  String get sellCreateAnother => 'Create another listing';

  @override
  String get sellTemplateImported =>
      'Template applied. Check every detail before submitting.';

  @override
  String get myListingsTitle => 'My listings';

  @override
  String get myListingsEmptyTitle => 'No listings yet';

  @override
  String get myListingsEmptyBody =>
      'Your submitted listings and review status will appear here.';

  @override
  String get listingStatusPending => 'Under review';

  @override
  String get listingStatusActive => 'Published';

  @override
  String get listingStatusRejected => 'Rejected';

  @override
  String get listingStatusDraft => 'Draft';

  @override
  String get listingStatusSold => 'Sold';

  @override
  String get listingStatusBlocked => 'Blocked';

  @override
  String get listingModerationReason => 'Reason';

  @override
  String get accountMyListings => 'My listings';

  @override
  String get accountModeration => 'Moderation';

  @override
  String get moderationTitle => 'Review listings';

  @override
  String get moderationPending => 'Pending';

  @override
  String get moderationApprovedToday => 'Approved today';

  @override
  String get moderationRejectedToday => 'Rejected today';

  @override
  String get moderationEmptyTitle => 'No pending listings';

  @override
  String get moderationEmptyBody =>
      'New submissions will appear here automatically.';

  @override
  String get moderationApprove => 'Approve';

  @override
  String get moderationReject => 'Reject';

  @override
  String get moderationReasonLabel => 'Reason (optional)';

  @override
  String get moderationReasonHint => 'Short feedback for the seller';

  @override
  String get moderationApproveSuccess => 'The listing is now public.';

  @override
  String get moderationRejectSuccess => 'The listing was rejected.';

  @override
  String get moderationForbiddenTitle => 'Administrators only';

  @override
  String get moderationForbiddenBody =>
      'You cannot access the moderation queue.';

  @override
  String get moderationSubmittedLabel => 'Submitted';

  @override
  String get moderationSellerLabel => 'Seller';

  @override
  String get moderationCategoryLabel => 'Category';

  @override
  String get moderationDecisionFailed => 'The decision could not be saved.';

  @override
  String get profileNotFoundTitle => 'Profile not found';

  @override
  String get profileNotFoundBody => 'This profile is not available.';

  @override
  String get profileFallbackName => 'Zêrîn member';

  @override
  String profileListingCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings',
      one: '1 listing',
      zero: 'No listings',
    );
    return '$_temp0';
  }

  @override
  String get profileAboutTitle => 'About';

  @override
  String get profileNoBio => 'No description yet.';

  @override
  String get profileListingsTitle => 'Active listings';

  @override
  String get profileNoListings => 'No active listings right now.';

  @override
  String get profileSendMessage => 'Send message';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get profileEditAvatar => 'Change photo';

  @override
  String get profileAvatarFromGallery => 'Choose from gallery';

  @override
  String get profileAvatarFromCamera => 'Take a photo';

  @override
  String get profileAvatarRemove => 'Remove photo';

  @override
  String get profileAvatarError => 'The profile photo could not be saved.';

  @override
  String get profileDisplayNameLabel => 'Display name';

  @override
  String get profileDisplayNameInvalid =>
      'Please enter a name with 1 to 80 characters.';

  @override
  String get profileUsernameLabel => 'Username';

  @override
  String get profileUsernameHelper =>
      '3–30 characters: lowercase letters, digits and underscores.';

  @override
  String get profileUsernameTaken => 'This username is already taken.';

  @override
  String get profileUsernameReserved => 'This username is reserved.';

  @override
  String get profileUsernameInvalid => 'This username is invalid.';

  @override
  String get profileCityLabel => 'City';

  @override
  String get profileCityRequired => 'Please choose a city.';

  @override
  String get profileCityInvalid => 'Please choose a supported German city.';

  @override
  String get profileBioLabel => 'About me';

  @override
  String get profileBioHint => 'Tell others a little about yourself.';

  @override
  String get profileBioTooLong =>
      'The description may contain at most 500 characters.';

  @override
  String get profileSave => 'Save profile';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyBody => 'Listings you save will appear here.';

  @override
  String get recentlyViewedTitle => 'Recently viewed';

  @override
  String get recentlyViewedEmptyTitle => 'Nothing viewed yet';

  @override
  String get recentlyViewedEmptyBody => 'Listings you view will appear here.';

  @override
  String get accountEditProfile => 'Edit profile';

  @override
  String get accountViewPublicProfile => 'Public profile';

  @override
  String get accountProfileIncomplete => 'Complete your profile';

  @override
  String get mapTitle => 'Map';

  @override
  String get mapOpenTooltip => 'Open map';

  @override
  String get mapUseMyLocation => 'Use my location';

  @override
  String get mapRetryLocation => 'Try location again';

  @override
  String get mapLocationPrivacy =>
      'Your location is used only to center the map and is never stored.';

  @override
  String get mapLocationDenied =>
      'Location access was denied. Choose a city instead.';

  @override
  String get mapLocationDeniedForever =>
      'Location access is disabled. Choose a city or change permission in Settings.';

  @override
  String get mapLocationServiceDisabled =>
      'Location services are off. Choose a city instead.';

  @override
  String get mapLocationUnavailable =>
      'Your location is unavailable right now. Choose a city instead.';

  @override
  String get mapChooseCity => 'Choose city';

  @override
  String get mapCitySearchHint => 'Search cities';

  @override
  String get mapCenterCurrent => 'Current location';

  @override
  String mapCenterCity({required String city}) {
    return 'Center: $city';
  }

  @override
  String get mapRadiusLabel => 'Radius';

  @override
  String get mapRadiusAll => 'All';

  @override
  String get mapFiltersTitle => 'Map filters';

  @override
  String get mapFiltersTooltip => 'Filter listings';

  @override
  String get mapCategoryLabel => 'Category';

  @override
  String get mapCategoryAll => 'All categories';

  @override
  String get mapConditionAll => 'All conditions';

  @override
  String get mapPriceMin => 'Minimum price (€)';

  @override
  String get mapPriceMax => 'Maximum price (€)';

  @override
  String get mapPriceInvalid =>
      'Enter valid prices; the minimum cannot be higher.';

  @override
  String mapListingsCount({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings on the map',
      one: '1 listing on the map',
      zero: 'No listings on the map',
    );
    return '$_temp0';
  }

  @override
  String get mapEmptyTitle => 'No listings in this radius';

  @override
  String get mapEmptyBody =>
      'Increase the radius, move the center, or adjust the filters.';

  @override
  String get mapLoading => 'Loading nearby listings …';

  @override
  String mapPinSemantic({required String title, required String city}) {
    return '$title, $city';
  }

  @override
  String mapClusterSemantic({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings',
      one: '1 listing',
    );
    return '$_temp0';
  }

  @override
  String get mapApproximateLocation =>
      'Approximate location protecting private sellers';

  @override
  String get mapPreciseStoreLocation =>
      'Precise location of a verified business';

  @override
  String get mapDirections => 'Get directions';

  @override
  String get mapDirectionsFailed => 'Directions could not be opened.';

  @override
  String get mapOpenListing => 'Open listing';

  @override
  String get moderationLoadFailed => 'Could not load moderation.';

  @override
  String get moderationAdminRequired => 'Administrator access required.';

  @override
  String get moderationTabOverview => 'Overview';

  @override
  String get moderationTabListings => 'Listings';

  @override
  String get moderationTabVerification => 'Seller verification';

  @override
  String get moderationTabReports => 'Reports';

  @override
  String get moderationOverviewPendingListings => 'Pending listings';

  @override
  String get moderationOverviewPendingDocuments => 'Pending seller documents';

  @override
  String get moderationOverviewOpenReports => 'Open reports';

  @override
  String get moderationListingsLoadFailed => 'Could not load listings.';

  @override
  String get moderationListingsEmpty => 'No pending listings.';

  @override
  String get moderationDocumentsLoadFailed =>
      'Could not load seller documents.';

  @override
  String get moderationDocumentsEmpty => 'No pending seller documents.';

  @override
  String get moderationOpenDocument => 'Open document';

  @override
  String get moderationDocumentKindMedicalProfessionalRegistration =>
      'Medical license / chamber registration';

  @override
  String moderationReportSeller({required String shopName}) {
    return 'Seller: $shopName';
  }

  @override
  String get moderationReportDismiss => 'Dismiss';

  @override
  String get moderationReportBlock => 'Block listing';

  @override
  String get moderationBlockConfirmTitle => 'Block this listing?';

  @override
  String moderationBlockConfirmBody({required String title}) {
    return 'This will block $title and resolve this report.';
  }

  @override
  String get moderationBlockConfirmAction => 'Block';

  @override
  String get moderationRejectionReasonTitle => 'Rejection reason';

  @override
  String get moderationReportFallbackTarget => 'the reported listing';

  @override
  String get moderationDocumentSaved => 'Document decision saved.';

  @override
  String get moderationDocumentFailed => 'Decision failed.';

  @override
  String get moderationReportResolved => 'Report resolved.';

  @override
  String get moderationReportActionFailed => 'Action failed.';

  @override
  String get moderationReportTargetUnavailable => 'Reported target unavailable';

  @override
  String get moderationReportsLoadFailed => 'Could not load reports.';

  @override
  String get moderationDocumentOpenFailed =>
      'The document could not be opened.';

  @override
  String get moderationReportsEmpty => 'No open reports.';

  @override
  String get sellCompareAtPriceLabel => 'Original price in euros (optional)';

  @override
  String get sellCompareAtPriceHint =>
      'Crossed-out price shown next to your price';

  @override
  String get sellValidationCompareAtPrice =>
      'The original price must be higher than your price.';

  @override
  String get mapOsmAttribution => '© OpenStreetMap contributors';

  @override
  String get businessHubTitle => 'My business';

  @override
  String get businessAccountEntrySubtitle =>
      'List a restaurant, café, snack bar or medical practice';

  @override
  String get businessStartTitle => 'Add your business';

  @override
  String get businessStartBody =>
      'First choose the type of listing. You will then see exactly which documents we need for it.';

  @override
  String get businessTypeLabel => 'Type of listing';

  @override
  String get businessNameLabel => 'Business name';

  @override
  String get businessStartAction => 'Continue to documents';

  @override
  String get businessPrivateSellerTitle => 'Private seller account';

  @override
  String get businessPrivateSellerBody =>
      'Your account sells as a private person. Directory listings require a business account. Please contact support.';

  @override
  String get businessStatusVerified => 'Verified';

  @override
  String get businessStatusInReview => 'In review';

  @override
  String get businessStatusDocumentsMissing => 'Documents missing';

  @override
  String get businessDocumentsTile => 'Documents';

  @override
  String businessDocumentsProgress({
    required int approved,
    required int total,
  }) {
    return '$approved of $total approved';
  }

  @override
  String get businessProfileTile => 'Profile';

  @override
  String get businessProfileMissing => 'Not created yet';

  @override
  String get businessProfileDraft => 'Draft – not public';

  @override
  String get businessProfilePublished => 'Published';

  @override
  String get businessHoursTile => 'Opening hours';

  @override
  String businessHoursSummary({required int count}) {
    return '$count time slots';
  }

  @override
  String get businessMenuTile => 'Menu';

  @override
  String businessMenuSummary({required int sections, required int items}) {
    return '$sections sections · $items dishes';
  }

  @override
  String get businessNeedsProfileFirst => 'Create your profile first.';

  @override
  String get businessPublishTitle => 'Show in the directory';

  @override
  String get businessPublishHintUnverified =>
      'You can publish once your documents are approved.';

  @override
  String get businessPublishOn => 'Your listing is publicly visible.';

  @override
  String get businessPublishOff => 'Only you can see your listing.';

  @override
  String get businessDraftNote =>
      'You can already prepare your profile, opening hours and menu as a draft.';

  @override
  String get directoryTypeRestaurant => 'Restaurant';

  @override
  String get directoryTypeCafe => 'Café';

  @override
  String get directoryTypeFastFood => 'Snack bar';

  @override
  String get directoryTypeDoctor => 'Medical practice';

  @override
  String businessDocumentsIntro({required String type}) {
    return 'For a listing as $type we need these documents. Only the Zêrîn team can see them.';
  }

  @override
  String get businessDocumentsFormats => 'Photo or PDF, up to 15 MB.';

  @override
  String get businessTypeLockedHint =>
      'You can now only change the type in your profile.';

  @override
  String get documentKindIdentity => 'ID card or passport';

  @override
  String get documentKindIdentityHint =>
      'Clearly legible with all corners visible.';

  @override
  String get documentKindBusinessRegistration =>
      'Business registration or commercial register extract';

  @override
  String get documentKindBusinessRegistrationHint =>
      'In the name of your business.';

  @override
  String get documentKindMedicalHint =>
      'Medical licence or proof of medical chamber membership.';

  @override
  String get documentStatusMissing => 'Missing';

  @override
  String get documentStatusPending => 'In review';

  @override
  String get documentStatusApproved => 'Approved';

  @override
  String get documentStatusRejected => 'Rejected';

  @override
  String documentRejectionNote({required String note}) {
    return 'Note from the team: $note';
  }

  @override
  String get documentUploadAction => 'Upload';

  @override
  String get documentReuploadAction => 'Upload again';

  @override
  String get documentWithdrawAction => 'Withdraw';

  @override
  String get documentSourceCamera => 'Take a photo';

  @override
  String get documentSourceGallery => 'Photo from gallery';

  @override
  String get documentSourcePdf => 'Choose a PDF';

  @override
  String get documentUploaded => 'Uploaded. We will review the document.';

  @override
  String get documentWithdrawn => 'Document withdrawn.';

  @override
  String documentUploadedAt({required String date}) {
    return 'Uploaded on $date';
  }

  @override
  String get businessErrorName => 'The name must be 2 to 100 characters long.';

  @override
  String get businessErrorCity => 'Please choose a city from the list.';

  @override
  String get businessErrorDocumentPending =>
      'A document for this is already waiting for review.';

  @override
  String get businessErrorFileTooLarge => 'The file is larger than 15 MB.';

  @override
  String get businessErrorInvalid => 'Please check your details.';

  @override
  String get businessCoverLabel => 'Cover image';

  @override
  String get businessCoverAction => 'Choose cover image';

  @override
  String get businessDescriptionLabel => 'Description';

  @override
  String get businessDescriptionHelper => '20 to 3000 characters';

  @override
  String get businessPhoneLabel => 'Phone';

  @override
  String get businessWebsiteLabel => 'Website (optional)';

  @override
  String get businessWebsiteHelper => 'Starts with https://';

  @override
  String get businessLanguagesLabel => 'Languages spoken';

  @override
  String get businessCuisinesLabel => 'Cuisine';

  @override
  String get businessPriceLevelLabel => 'Price level';

  @override
  String get businessDietLabel => 'Dietary options';

  @override
  String get businessHalal => 'Halal';

  @override
  String get businessVegetarian => 'Vegetarian dishes';

  @override
  String get businessVegan => 'Vegan dishes';

  @override
  String get businessSpecialtyLabel => 'Specialty';

  @override
  String get businessInsuranceLabel => 'Insurance';

  @override
  String get insuranceStatutory => 'Statutory';

  @override
  String get insurancePrivate => 'Private';

  @override
  String get insuranceBoth => 'Statutory and private';

  @override
  String get businessSaved => 'Saved.';

  @override
  String get businessDescriptionInvalid =>
      'The description must be 20 to 3000 characters long.';

  @override
  String get businessPhoneInvalid =>
      'Please enter a phone number with 5 to 40 characters.';

  @override
  String get businessWebsiteInvalid => 'The website must start with https://.';

  @override
  String get businessLanguagesRequired => 'Choose at least one language.';

  @override
  String get businessCuisinesRequired => 'Choose at least one cuisine.';

  @override
  String get businessPriceRequired => 'Choose a price level.';

  @override
  String get businessSpecialtyRequired => 'Choose a specialty.';

  @override
  String get businessInsuranceRequired => 'Choose which insurance you accept.';

  @override
  String get cuisineKurdish => 'Kurdish';

  @override
  String get cuisineSyrian => 'Syrian';

  @override
  String get cuisineTurkish => 'Turkish';

  @override
  String get cuisineArabic => 'Arabic';

  @override
  String get cuisinePersian => 'Persian';

  @override
  String get cuisineLebanese => 'Lebanese';

  @override
  String get cuisineIraqi => 'Iraqi';

  @override
  String get cuisineMiddleEastern => 'Middle Eastern';

  @override
  String get cuisineKebab => 'Kebab & döner';

  @override
  String get cuisineFalafel => 'Falafel';

  @override
  String get cuisineGerman => 'German';

  @override
  String get cuisineItalian => 'Italian';

  @override
  String get cuisineMediterranean => 'Mediterranean';

  @override
  String get cuisineIndian => 'Indian';

  @override
  String get cuisineAsian => 'Asian';

  @override
  String get cuisineInternational => 'International';

  @override
  String get specialtyGeneralMedicine => 'General medicine';

  @override
  String get specialtyInternalMedicine => 'Internal medicine';

  @override
  String get specialtyPediatrics => 'Pediatrics';

  @override
  String get specialtyGynecology => 'Gynecology';

  @override
  String get specialtyDermatology => 'Dermatology';

  @override
  String get specialtyOrthopedics => 'Orthopedics';

  @override
  String get specialtyNeurology => 'Neurology';

  @override
  String get specialtyPsychiatry => 'Psychiatry';

  @override
  String get specialtyOphthalmology => 'Ophthalmology';

  @override
  String get specialtyEnt => 'ENT';

  @override
  String get specialtyDentistry => 'Dentistry';

  @override
  String get specialtyCardiology => 'Cardiology';

  @override
  String get specialtyUrology => 'Urology';

  @override
  String get specialtyOther => 'Other';

  @override
  String get businessHoursClosed => 'Closed';

  @override
  String get businessHoursAdd => 'Add time slot';

  @override
  String businessHoursInterval({
    required String opens,
    required String closes,
  }) {
    return '$opens – $closes';
  }

  @override
  String businessHoursOvernight({
    required String opens,
    required String closes,
  }) {
    return '$opens – $closes (next day)';
  }

  @override
  String get businessHoursPickOpen => 'Opens at';

  @override
  String get businessHoursPickClose => 'Closes at';

  @override
  String get businessHoursHint =>
      'If you close after midnight, simply choose the time the next morning.';

  @override
  String get businessHoursSameTime => 'Opening and closing time must differ.';

  @override
  String get businessHoursTooMany => 'At most 6 time slots per day.';

  @override
  String get businessHoursRemove => 'Remove time slot';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get businessMenuEmpty =>
      'No sections yet. Add, for example, “Starters” or “Drinks”.';

  @override
  String get businessMenuAddSection => 'Add section';

  @override
  String get businessMenuSectionName => 'Section name';

  @override
  String get businessMenuAddItem => 'Add dish';

  @override
  String get businessMenuEditItem => 'Edit dish';

  @override
  String get businessMenuItemName => 'Name';

  @override
  String get businessMenuItemDescription => 'Description (optional)';

  @override
  String get businessMenuItemPrice => 'Price in €';

  @override
  String get businessMenuItemAvailable => 'Available';

  @override
  String get businessMenuItemUnavailable => 'Unavailable';

  @override
  String get businessMenuMoveUp => 'Move up';

  @override
  String get businessMenuMoveDown => 'Move down';

  @override
  String get businessMenuPriceInvalid => 'Please enter a valid price.';

  @override
  String get businessMenuNameRequired => 'Please enter a name.';

  @override
  String businessMenuDeleteSection({required String name}) {
    return 'Delete section “$name” with all its dishes?';
  }

  @override
  String get menuFlagVegetarian => 'Vegetarian';

  @override
  String get menuFlagVegan => 'Vegan';
}
