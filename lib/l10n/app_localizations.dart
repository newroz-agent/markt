import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ar'),
    Locale('tr'),
  ];

  /// Public brand name of the marketplace.
  ///
  /// In de, this message translates to:
  /// **'Zêrîn'**
  String get appName;

  /// Short brand promise shown during onboarding.
  ///
  /// In de, this message translates to:
  /// **'Dein Marktplatz. Besonders gut.'**
  String get appTagline;

  /// Label for the home navigation destination.
  ///
  /// In de, this message translates to:
  /// **'Startseite'**
  String get navigationHome;

  /// Label for the categories navigation destination.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get navigationCategories;

  /// Label for the central sell navigation destination.
  ///
  /// In de, this message translates to:
  /// **'Verkaufen'**
  String get navigationSell;

  /// Label for the cart navigation destination.
  ///
  /// In de, this message translates to:
  /// **'Warenkorb'**
  String get navigationCart;

  /// Label for the account navigation destination.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get navigationAccount;

  /// Label for the favorites destination.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get navigationFavorites;

  /// Label for the orders destination.
  ///
  /// In de, this message translates to:
  /// **'Bestellungen'**
  String get navigationOrders;

  /// Label for the messages destination.
  ///
  /// In de, this message translates to:
  /// **'Nachrichten'**
  String get navigationMessages;

  /// Label for the settings destination.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navigationSettings;

  /// Generic continue action.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get actionContinue;

  /// Generic skip action.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get actionSkip;

  /// Action that completes onboarding.
  ///
  /// In de, this message translates to:
  /// **'Los geht’s'**
  String get actionGetStarted;

  /// Action that advances to the next step.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get actionNext;

  /// Generic back action.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get actionBack;

  /// Generic close action.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get actionClose;

  /// Generic cancel action.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get actionCancel;

  /// Generic save action.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get actionSave;

  /// Generic done action.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get actionDone;

  /// Action used to retry a failed operation.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get actionRetry;

  /// Action used to open a complete list.
  ///
  /// In de, this message translates to:
  /// **'Alle anzeigen'**
  String get actionSeeAll;

  /// Generic search action.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get actionSearch;

  /// Action used to apply filters or settings.
  ///
  /// In de, this message translates to:
  /// **'Anwenden'**
  String get actionApply;

  /// Action used to clear all selected values.
  ///
  /// In de, this message translates to:
  /// **'Alle löschen'**
  String get actionClearAll;

  /// Generic confirm action.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get actionConfirm;

  /// Generic edit action.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get actionEdit;

  /// Generic delete action.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get actionDelete;

  /// Action used to sign in.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get actionSignIn;

  /// Action used to create an account.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get actionSignUp;

  /// Action used to sign out.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get actionSignOut;

  /// Accessible status text for loading content.
  ///
  /// In de, this message translates to:
  /// **'Wird geladen …'**
  String get stateLoading;

  /// Generic error-state title.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt'**
  String get stateErrorTitle;

  /// Generic recoverable error-state message.
  ///
  /// In de, this message translates to:
  /// **'Bitte versuche es gleich noch einmal.'**
  String get stateErrorMessage;

  /// Offline-state title.
  ///
  /// In de, this message translates to:
  /// **'Du bist offline'**
  String get stateOfflineTitle;

  /// Offline-state explanatory message.
  ///
  /// In de, this message translates to:
  /// **'Prüfe deine Internetverbindung und versuche es erneut.'**
  String get stateOfflineMessage;

  /// Generic empty-state title.
  ///
  /// In de, this message translates to:
  /// **'Hier ist noch nichts'**
  String get stateEmptyTitle;

  /// Title for a guest authentication gate.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung erforderlich'**
  String get authRequiredTitle;

  /// Message explaining that a guest must sign in.
  ///
  /// In de, this message translates to:
  /// **'Melde dich an, um diese Funktion zu nutzen.'**
  String get authRequiredMessage;

  /// Title of the first onboarding page.
  ///
  /// In de, this message translates to:
  /// **'Alles, was du liebst. An einem Ort.'**
  String get onboardingWelcomeTitle;

  /// Body copy of the first onboarding page.
  ///
  /// In de, this message translates to:
  /// **'Entdecke ausgewählte Produkte von Shops und privaten Verkäufern in ganz Deutschland.'**
  String get onboardingWelcomeBody;

  /// Title of the second onboarding page.
  ///
  /// In de, this message translates to:
  /// **'Finde Besonderes in deiner Nähe'**
  String get onboardingDiscoverTitle;

  /// Body copy of the second onboarding page.
  ///
  /// In de, this message translates to:
  /// **'Suche, filtere und vergleiche neue und gebrauchte Artikel – sicher und transparent.'**
  String get onboardingDiscoverBody;

  /// Title of the third onboarding page.
  ///
  /// In de, this message translates to:
  /// **'Verkaufe einfach und sicher'**
  String get onboardingSellTitle;

  /// Body copy of the third onboarding page.
  ///
  /// In de, this message translates to:
  /// **'Stelle Artikel in wenigen Minuten ein oder baue deinen eigenen Shop auf.'**
  String get onboardingSellBody;

  /// Welcome title on the authentication entry screen.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei Zêrîn'**
  String get authWelcomeTitle;

  /// Benefits copy on the authentication entry screen.
  ///
  /// In de, this message translates to:
  /// **'Melde dich an, um Favoriten zu speichern, einzukaufen und zu verkaufen.'**
  String get authWelcomeBody;

  /// Title of the sign-in screen.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get authSignInTitle;

  /// Supporting copy on the sign-in screen.
  ///
  /// In de, this message translates to:
  /// **'Schön, dass du wieder da bist.'**
  String get authSignInSubtitle;

  /// Title of the registration screen.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get authSignUpTitle;

  /// Supporting copy on the registration screen.
  ///
  /// In de, this message translates to:
  /// **'Erstelle dein Konto in wenigen Schritten.'**
  String get authSignUpSubtitle;

  /// Label for the display-name input during registration.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get authDisplayNameLabel;

  /// Hint for the display-name input during registration.
  ///
  /// In de, this message translates to:
  /// **'Vor- und Nachname'**
  String get authDisplayNameHint;

  /// Label for an email-address input.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse'**
  String get authEmailLabel;

  /// Example hint for an email-address input.
  ///
  /// In de, this message translates to:
  /// **'name@beispiel.de'**
  String get authEmailHint;

  /// Label for a password input.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get authPasswordLabel;

  /// Hint describing the minimum password requirement.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 8 Zeichen'**
  String get authPasswordHint;

  /// Label for a password confirmation input.
  ///
  /// In de, this message translates to:
  /// **'Passwort bestätigen'**
  String get authConfirmPasswordLabel;

  /// Action opening the password reset flow.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get authForgotPassword;

  /// Title of the password reset screen.
  ///
  /// In de, this message translates to:
  /// **'Passwort zurücksetzen'**
  String get authResetPasswordTitle;

  /// Instructions on the password reset screen.
  ///
  /// In de, this message translates to:
  /// **'Wir senden dir einen Link, mit dem du ein neues Passwort festlegen kannst.'**
  String get authResetPasswordBody;

  /// Action that sends a password reset link.
  ///
  /// In de, this message translates to:
  /// **'Link senden'**
  String get authSendResetLink;

  /// Confirmation shown after requesting a reset link.
  ///
  /// In de, this message translates to:
  /// **'Der Link zum Zurücksetzen wurde gesendet.'**
  String get authResetLinkSent;

  /// Prompt shown to users who do not have an account.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Konto?'**
  String get authNoAccount;

  /// Prompt shown to registered users on the registration screen.
  ///
  /// In de, this message translates to:
  /// **'Du hast bereits ein Konto?'**
  String get authHaveAccount;

  /// Google authentication action.
  ///
  /// In de, this message translates to:
  /// **'Mit Google fortfahren'**
  String get authContinueWithGoogle;

  /// Apple authentication action.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple fortfahren'**
  String get authContinueWithApple;

  /// Action that enters the app without authenticating.
  ///
  /// In de, this message translates to:
  /// **'Als Gast fortfahren'**
  String get authContinueAsGuest;

  /// Separator between social and email authentication methods.
  ///
  /// In de, this message translates to:
  /// **'oder'**
  String get authOrSeparator;

  /// Consent notice shown beside authentication actions.
  ///
  /// In de, this message translates to:
  /// **'Mit deiner Anmeldung stimmst du unseren AGB und unserer Datenschutzerklärung zu.'**
  String get authTermsAgreement;

  /// Error shown when sign-in credentials are invalid.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse oder Passwort ist nicht korrekt.'**
  String get authInvalidCredentials;

  /// Error shown when authentication backend configuration is missing.
  ///
  /// In de, this message translates to:
  /// **'Der Anmeldedienst ist für diese Vorschau noch nicht eingerichtet.'**
  String get authBackendNotConfigured;

  /// Error shown when a user tries to sign in before confirming their email.
  ///
  /// In de, this message translates to:
  /// **'Bitte bestätige zuerst deine E-Mail-Adresse.'**
  String get authEmailNotConfirmed;

  /// Error shown when an email address is already registered.
  ///
  /// In de, this message translates to:
  /// **'Für diese E-Mail-Adresse besteht bereits ein Konto.'**
  String get authEmailAlreadyRegistered;

  /// Error shown when the authentication provider rejects a weak password.
  ///
  /// In de, this message translates to:
  /// **'Dieses Passwort ist zu schwach. Verwende mindestens 8 Zeichen.'**
  String get authWeakPassword;

  /// Error shown when authentication fails because of connectivity.
  ///
  /// In de, this message translates to:
  /// **'Die Verbindung ist fehlgeschlagen. Prüfe deine Internetverbindung.'**
  String get authNetworkError;

  /// Fallback error for an unrecognized authentication failure.
  ///
  /// In de, this message translates to:
  /// **'Die Anmeldung ist fehlgeschlagen. Bitte versuche es erneut.'**
  String get authUnknownError;

  /// Success message after registration when email confirmation is required.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellt. Prüfe jetzt dein E-Mail-Postfach, um deine Adresse zu bestätigen.'**
  String get authRegistrationCheckEmail;

  /// Title of the email-verification screen.
  ///
  /// In de, this message translates to:
  /// **'Bestätige deine E-Mail-Adresse'**
  String get authEmailVerificationTitle;

  /// Message explaining where the email-verification link was sent.
  ///
  /// In de, this message translates to:
  /// **'Wir haben einen Bestätigungslink an {email} gesendet.'**
  String authEmailVerificationBody({required String email});

  /// Action that resends an email-verification link.
  ///
  /// In de, this message translates to:
  /// **'E-Mail erneut senden'**
  String get authResendVerification;

  /// Validation error for a required field.
  ///
  /// In de, this message translates to:
  /// **'Dieses Feld ist erforderlich.'**
  String get validationRequired;

  /// Validation error for an invalid email address.
  ///
  /// In de, this message translates to:
  /// **'Gib eine gültige E-Mail-Adresse ein.'**
  String get validationInvalidEmail;

  /// Validation error for a password that is too short.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort muss mindestens {minLength} Zeichen lang sein.'**
  String validationPasswordMinLength({required int minLength});

  /// Validation error for non-matching passwords.
  ///
  /// In de, this message translates to:
  /// **'Die Passwörter stimmen nicht überein.'**
  String get validationPasswordMismatch;

  /// Generic greeting on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Hallo!'**
  String get homeGreeting;

  /// Personalized greeting on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Hallo, {name}!'**
  String homeGreetingNamed({required String name});

  /// Placeholder for the marketplace search input.
  ///
  /// In de, this message translates to:
  /// **'Wonach suchst du?'**
  String get homeSearchHint;

  /// Heading for category shortcuts on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get homeCategoriesTitle;

  /// Heading for discounted products on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Angebote & Rabatte'**
  String get homeDealsTitle;

  /// Heading for newly listed products on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Neu eingetroffen'**
  String get homeNewArrivalsTitle;

  /// Heading for locally popular products on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Beliebt in deiner Nähe'**
  String get homePopularNearbyTitle;

  /// Heading for recently viewed products on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt angesehen'**
  String get homeRecentlyViewedTitle;

  /// Title of the categories screen.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get categoriesTitle;

  /// Placeholder for category search.
  ///
  /// In de, this message translates to:
  /// **'Kategorien durchsuchen'**
  String get categoriesSearchHint;

  /// Title shown when no category matches a search.
  ///
  /// In de, this message translates to:
  /// **'Keine Kategorien gefunden'**
  String get categoriesEmptyTitle;

  /// Message shown when no category matches a search.
  ///
  /// In de, this message translates to:
  /// **'Versuche es mit einem anderen Suchbegriff.'**
  String get categoriesEmptyBody;

  /// Title of the sell entry screen.
  ///
  /// In de, this message translates to:
  /// **'Verkaufen'**
  String get sellTitle;

  /// Title of the private-listing path.
  ///
  /// In de, this message translates to:
  /// **'Privat verkaufen'**
  String get sellPrivateTitle;

  /// Description of the private-listing path.
  ///
  /// In de, this message translates to:
  /// **'Stelle deinen Artikel in wenigen Minuten ein.'**
  String get sellPrivateBody;

  /// Title of the professional seller onboarding path.
  ///
  /// In de, this message translates to:
  /// **'Verkäufer werden'**
  String get sellVendorTitle;

  /// Description of the professional seller onboarding path.
  ///
  /// In de, this message translates to:
  /// **'Eröffne deinen Shop und erreiche Kundinnen und Kunden in ganz Deutschland.'**
  String get sellVendorBody;

  /// Title of the cart screen.
  ///
  /// In de, this message translates to:
  /// **'Warenkorb'**
  String get cartTitle;

  /// Title of the empty cart state.
  ///
  /// In de, this message translates to:
  /// **'Dein Warenkorb ist leer'**
  String get cartEmptyTitle;

  /// Message in the empty cart state.
  ///
  /// In de, this message translates to:
  /// **'Entdecke Produkte und füge deine Favoriten hinzu.'**
  String get cartEmptyBody;

  /// Number of items in the cart.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0 {Keine Artikel} one {1 Artikel} other {{count} Artikel}}'**
  String cartItemCount({required int count});

  /// Label for the cart subtotal.
  ///
  /// In de, this message translates to:
  /// **'Zwischensumme'**
  String get cartSubtotal;

  /// Label for shipping costs.
  ///
  /// In de, this message translates to:
  /// **'Versand'**
  String get cartShipping;

  /// Notice that value-added tax is included.
  ///
  /// In de, this message translates to:
  /// **'inkl. MwSt.'**
  String get cartVatIncluded;

  /// Label for the final cart total.
  ///
  /// In de, this message translates to:
  /// **'Gesamtsumme'**
  String get cartTotal;

  /// Action that starts checkout.
  ///
  /// In de, this message translates to:
  /// **'Zur Kasse'**
  String get cartCheckout;

  /// Title of the account screen.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get accountTitle;

  /// Account menu item for profile details.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Daten'**
  String get accountProfile;

  /// Account menu item for saved addresses.
  ///
  /// In de, this message translates to:
  /// **'Adressen'**
  String get accountAddresses;

  /// Account menu item for language selection.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get accountLanguage;

  /// Account menu item for theme selection.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get accountAppearance;

  /// Account menu item for notification settings.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get accountNotifications;

  /// Account menu item for legal information.
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get accountLegal;

  /// Account action that starts account deletion.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get accountDelete;

  /// Title of the account screen for a guest user.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei Zêrîn'**
  String get accountGuestTitle;

  /// Benefits message on the account screen for a guest user.
  ///
  /// In de, this message translates to:
  /// **'Melde dich an, um Bestellungen, Favoriten und deine Verkäufe zu verwalten.'**
  String get accountGuestBody;

  /// Title of the temporary Phase 1 foundation preview.
  ///
  /// In de, this message translates to:
  /// **'Dein Marktplatz nimmt Form an'**
  String get foundationPreviewTitle;

  /// Body copy of the temporary Phase 1 foundation preview.
  ///
  /// In de, this message translates to:
  /// **'Designsystem, Navigation, Sprachen und Anmeldung sind bereit. Weitere Marktplatzfunktionen folgen.'**
  String get foundationPreviewBody;

  /// Display name for the German language.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// Display name for the English language.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get languageEnglish;

  /// Display name for the Arabic language.
  ///
  /// In de, this message translates to:
  /// **'Arabisch'**
  String get languageArabic;

  /// Display name for the Turkish language.
  ///
  /// In de, this message translates to:
  /// **'Türkisch'**
  String get languageTurkish;

  /// Theme option that follows the operating system.
  ///
  /// In de, this message translates to:
  /// **'Systemeinstellung'**
  String get themeSystem;

  /// Light theme option.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// Dark theme option.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// Badge for a new product.
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get productConditionNew;

  /// Badge for a used product.
  ///
  /// In de, this message translates to:
  /// **'Gebraucht'**
  String get productConditionUsed;

  /// A localized, preformatted price followed by the VAT notice.
  ///
  /// In de, this message translates to:
  /// **'{price} inkl. MwSt.'**
  String productVatIncluded({required String price});

  /// Badge for free shipping.
  ///
  /// In de, this message translates to:
  /// **'Kostenloser Versand'**
  String get productFreeShipping;

  /// Accessible label for adding a product to favorites.
  ///
  /// In de, this message translates to:
  /// **'Zu Favoriten hinzufügen'**
  String get favoriteAdd;

  /// Accessible label for removing a product from favorites.
  ///
  /// In de, this message translates to:
  /// **'Aus Favoriten entfernen'**
  String get favoriteRemove;

  /// Action that adds a product to the cart.
  ///
  /// In de, this message translates to:
  /// **'In den Warenkorb'**
  String get cartAdd;

  /// Number of search or category results.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0 {Keine Ergebnisse} one {1 Ergebnis} other {{count} Ergebnisse}}'**
  String resultsCount({required int count});

  /// Accessible label for the selected navigation tab.
  ///
  /// In de, this message translates to:
  /// **'{label}, ausgewählt'**
  String semanticsSelectedTab({required String label});

  /// Accessible cart label including its item count.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0 {Warenkorb, keine Artikel} one {Warenkorb, 1 Artikel} other {Warenkorb, {count} Artikel}}'**
  String semanticsCartItemCount({required int count});

  /// Label for the legally required imprint.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get legalImprint;

  /// Label for terms and conditions.
  ///
  /// In de, this message translates to:
  /// **'AGB'**
  String get legalTerms;

  /// Label for the privacy policy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get legalPrivacy;

  /// Label for withdrawal-right information.
  ///
  /// In de, this message translates to:
  /// **'Widerrufsbelehrung'**
  String get legalWithdrawal;

  /// Temporary notice used before final legal documents are published.
  ///
  /// In de, this message translates to:
  /// **'Die vollständigen rechtlichen Inhalte werden vor der Veröffentlichung bereitgestellt.'**
  String get legalComingSoonBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
