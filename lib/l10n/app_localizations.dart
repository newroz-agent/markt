import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ku.dart';
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
    Locale('ku'),
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

  /// Compact action that opens the complete category list.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get homeAllCategoriesLabel;

  /// Heading for discounted products on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Angebote'**
  String get homeDealsTitle;

  /// Heading for newly listed products on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Neu eingetroffen'**
  String get homeNewArrivalsTitle;

  /// Heading for popular stores on the home screen.
  ///
  /// In de, this message translates to:
  /// **'Beliebte Geschäfte'**
  String get homePopularStoresTitle;

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

  /// Display name for the Kurdish (Kurmanji) language. Shown as the endonym in every locale so Kurdish speakers recognize it whatever the UI language is.
  ///
  /// In de, this message translates to:
  /// **'Kurdî'**
  String get languageKurdish;

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

  /// Shown when a legal document slug does not match a known document.
  ///
  /// In de, this message translates to:
  /// **'Dieses rechtliche Dokument existiert nicht.'**
  String get legalUnknownDocumentBody;

  /// Title of the error state when a legal document fails to load.
  ///
  /// In de, this message translates to:
  /// **'Dokument nicht geladen'**
  String get legalLoadErrorTitle;

  /// Body of the error state when a legal document fails to load.
  ///
  /// In de, this message translates to:
  /// **'Der Text konnte nicht abgerufen werden. Prüfe deine Internetverbindung.'**
  String get legalLoadErrorBody;

  /// Version and effective date shown above the body of a legal document.
  ///
  /// In de, this message translates to:
  /// **'Fassung {version} · gültig ab {date}'**
  String legalVersionLine({required String version, required String date});

  /// Snackbar shown when a link inside a legal document cannot be opened.
  ///
  /// In de, this message translates to:
  /// **'Der Link konnte nicht geöffnet werden.'**
  String get legalLinkFailed;

  /// Account menu item leading to the privacy and data screen.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Daten'**
  String get accountPrivacy;

  /// Title of the privacy and data screen.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Daten'**
  String get privacyTitle;

  /// Empty state title shown when privacy settings are opened without a session.
  ///
  /// In de, this message translates to:
  /// **'Melde dich an'**
  String get privacySignedOutTitle;

  /// Empty state body shown when privacy settings are opened without a session.
  ///
  /// In de, this message translates to:
  /// **'Deine Datenschutzeinstellungen gehören zu deinem Konto.'**
  String get privacySignedOutBody;

  /// Label of the analytics consent switch.
  ///
  /// In de, this message translates to:
  /// **'Analyse erlauben'**
  String get privacyAnalyticsTitle;

  /// Explanation of what the analytics consent covers.
  ///
  /// In de, this message translates to:
  /// **'Hilft uns, Fehler zu finden und die App zu verbessern. Du kannst das jederzeit widerrufen.'**
  String get privacyAnalyticsBody;

  /// Shows when the user granted analytics consent.
  ///
  /// In de, this message translates to:
  /// **'Erteilt am {date}'**
  String privacyAnalyticsGrantedAt({required String date});

  /// Section heading for data export and account deletion.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten'**
  String get privacyDataSectionTitle;

  /// Label of the DSGVO data-export action.
  ///
  /// In de, this message translates to:
  /// **'Daten exportieren'**
  String get privacyExportTitle;

  /// Explanation of the data-export action.
  ///
  /// In de, this message translates to:
  /// **'Wir stellen dir eine Kopie deiner Daten zum Download bereit.'**
  String get privacyExportBody;

  /// Button that requests a data export.
  ///
  /// In de, this message translates to:
  /// **'Export anfordern'**
  String get privacyExportRequest;

  /// Status shown while a data export is being generated.
  ///
  /// In de, this message translates to:
  /// **'Dein Export wird vorbereitet. Wir benachrichtigen dich, sobald er bereit ist.'**
  String get privacyExportPending;

  /// Status shown when a data export can be downloaded.
  ///
  /// In de, this message translates to:
  /// **'Dein Export ist bereit.'**
  String get privacyExportReady;

  /// Status shown when a finished export is past its retention window.
  ///
  /// In de, this message translates to:
  /// **'Dieser Export ist abgelaufen. Fordere einen neuen an.'**
  String get privacyExportExpired;

  /// Button that downloads a finished data export.
  ///
  /// In de, this message translates to:
  /// **'Herunterladen'**
  String get privacyExportDownload;

  /// Snackbar confirming a data export was queued.
  ///
  /// In de, this message translates to:
  /// **'Export angefordert.'**
  String get privacyExportRequested;

  /// Label of the account deletion action.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get privacyDeleteTitle;

  /// Explains what account deletion does and what is legally retained.
  ///
  /// In de, this message translates to:
  /// **'Löscht dein Konto und deine persönlichen Daten. Bestellungen bleiben aus steuerrechtlichen Gründen gespeichert.'**
  String get privacyDeleteBody;

  /// Title of the account deletion confirmation dialog.
  ///
  /// In de, this message translates to:
  /// **'Konto wirklich löschen?'**
  String get privacyDeleteConfirmTitle;

  /// Instruction in the deletion dialog telling the user which word to type.
  ///
  /// In de, this message translates to:
  /// **'Tippe {word}, um zu bestätigen. Du kannst die Löschung anschließend noch abbrechen, solange sie nicht bearbeitet wird.'**
  String privacyDeleteConfirmBody({required String word});

  /// Label of the text field in the deletion confirmation dialog.
  ///
  /// In de, this message translates to:
  /// **'Bestätigung'**
  String get privacyDeleteConfirmLabel;

  /// Status shown while an account deletion request is pending.
  ///
  /// In de, this message translates to:
  /// **'Deine Löschung ist angefordert. Du kannst sie noch abbrechen.'**
  String get privacyDeletePending;

  /// Status shown once an account deletion is being processed.
  ///
  /// In de, this message translates to:
  /// **'Deine Löschung wird bearbeitet und kann nicht mehr abgebrochen werden.'**
  String get privacyDeleteProcessing;

  /// Snackbar confirming an account deletion was requested.
  ///
  /// In de, this message translates to:
  /// **'Löschung angefordert.'**
  String get privacyDeleteRequested;

  /// Button that cancels a pending account deletion.
  ///
  /// In de, this message translates to:
  /// **'Löschung abbrechen'**
  String get privacyDeleteCancel;

  /// Snackbar confirming a pending deletion was cancelled.
  ///
  /// In de, this message translates to:
  /// **'Löschung abgebrochen.'**
  String get privacyDeleteCancelled;

  /// Snackbar shown when cancelling a deletion came too late.
  ///
  /// In de, this message translates to:
  /// **'Die Löschung wird bereits bearbeitet und kann nicht mehr abgebrochen werden.'**
  String get privacyDeleteCancelFailed;

  /// Title of the notification preferences screen.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notificationsTitle;

  /// Introduction on the notification preferences screen.
  ///
  /// In de, this message translates to:
  /// **'Wähle, worüber wir dich informieren dürfen.'**
  String get notificationsBody;

  /// Notification channel for order status changes.
  ///
  /// In de, this message translates to:
  /// **'Bestellungen'**
  String get notificationsOrders;

  /// Explains the orders notification channel.
  ///
  /// In de, this message translates to:
  /// **'Zahlung, Versand und Zustellung.'**
  String get notificationsOrdersBody;

  /// Notification channel for chat messages.
  ///
  /// In de, this message translates to:
  /// **'Nachrichten'**
  String get notificationsChat;

  /// Explains the chat notification channel.
  ///
  /// In de, this message translates to:
  /// **'Neue Nachrichten von Käufern und Verkäufern.'**
  String get notificationsChatBody;

  /// Notification channel for marketing offers.
  ///
  /// In de, this message translates to:
  /// **'Angebote'**
  String get notificationsOffers;

  /// Explains the offers notification channel.
  ///
  /// In de, this message translates to:
  /// **'Aktionen und Empfehlungen. Standardmäßig aus.'**
  String get notificationsOffersBody;

  /// Notification channel for price drops on favorites.
  ///
  /// In de, this message translates to:
  /// **'Preisalarm'**
  String get notificationsPriceDrops;

  /// Explains the price-drop notification channel.
  ///
  /// In de, this message translates to:
  /// **'Wenn ein Favorit günstiger wird.'**
  String get notificationsPriceDropsBody;

  /// Notification channel for security and account messages.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get notificationsSystem;

  /// Explains the system notification channel.
  ///
  /// In de, this message translates to:
  /// **'Sicherheit und wichtige Kontohinweise.'**
  String get notificationsSystemBody;

  /// Snackbar shown when a notification preference could not be saved.
  ///
  /// In de, this message translates to:
  /// **'Die Einstellung konnte nicht gespeichert werden.'**
  String get notificationsSaveFailed;

  /// Empty state title shown when notification settings are opened without a session.
  ///
  /// In de, this message translates to:
  /// **'Melde dich an'**
  String get notificationsSignedOutTitle;

  /// Empty state body shown when notification settings are opened without a session.
  ///
  /// In de, this message translates to:
  /// **'Deine Benachrichtigungen gehören zu deinem Konto.'**
  String get notificationsSignedOutBody;

  /// Chip that selects all subcategories of a category.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get categoryProductsAll;

  /// Title shown when a category has no visible products.
  ///
  /// In de, this message translates to:
  /// **'Keine Angebote'**
  String get categoryProductsEmptyTitle;

  /// Message shown when a category has no visible products.
  ///
  /// In de, this message translates to:
  /// **'Es gibt noch keine passenden Angebote in dieser Kategorie.'**
  String get categoryProductsEmptyBody;

  /// Label for the condition filter.
  ///
  /// In de, this message translates to:
  /// **'Zustand'**
  String get filterConditionLabel;

  /// Chip that disables the condition filter.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterConditionAll;

  /// Semantic label for the sort menu.
  ///
  /// In de, this message translates to:
  /// **'Sortierung'**
  String get filterSortLabel;

  /// Sort option: newest listings first.
  ///
  /// In de, this message translates to:
  /// **'Neueste'**
  String get filterSortNewest;

  /// Sort option: cheapest listings first.
  ///
  /// In de, this message translates to:
  /// **'Preis: aufsteigend'**
  String get filterSortPriceAsc;

  /// Sort option: most expensive listings first.
  ///
  /// In de, this message translates to:
  /// **'Preis: absteigend'**
  String get filterSortPriceDesc;

  /// Label for the seller type filter.
  ///
  /// In de, this message translates to:
  /// **'Verkäuferart'**
  String get filterSellerKindLabel;

  /// Chip that disables the seller type filter.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterSellerKindAll;

  /// Chip for private sellers.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get filterSellerKindPrivate;

  /// Chip for business sellers.
  ///
  /// In de, this message translates to:
  /// **'Gewerblich'**
  String get filterSellerKindBusiness;

  /// Label for the city filter entry point.
  ///
  /// In de, this message translates to:
  /// **'Stadt'**
  String get filterCityLabel;

  /// Option that disables the city filter.
  ///
  /// In de, this message translates to:
  /// **'Überall'**
  String get filterCityAll;

  /// Title of the German city selection sheet.
  ///
  /// In de, this message translates to:
  /// **'Stadt wählen'**
  String get filterCityTitle;

  /// Toggle to the grid results view.
  ///
  /// In de, this message translates to:
  /// **'Raster'**
  String get categoryViewGrid;

  /// Toggle to the list results view.
  ///
  /// In de, this message translates to:
  /// **'Liste'**
  String get categoryViewList;

  /// Hint for the in-category title search.
  ///
  /// In de, this message translates to:
  /// **'In dieser Kategorie suchen'**
  String get categorySearchInCategory;

  /// Button that loads the next page of listings.
  ///
  /// In de, this message translates to:
  /// **'Mehr laden'**
  String get categoryProductsLoadMore;

  /// End of pagination caption.
  ///
  /// In de, this message translates to:
  /// **'Keine weiteren Anzeigen'**
  String get categoryProductsNoMore;

  /// Button that opens a conversation with the seller.
  ///
  /// In de, this message translates to:
  /// **'Verkäufer kontaktieren'**
  String get productContactSeller;

  /// Title of the conversations inbox.
  ///
  /// In de, this message translates to:
  /// **'Nachrichten'**
  String get chatInboxTitle;

  /// Title shown when the conversations inbox is empty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten'**
  String get chatInboxEmptyTitle;

  /// Explanation shown when the conversations inbox is empty.
  ///
  /// In de, this message translates to:
  /// **'Deine Unterhaltungen mit Käufern und Verkäufern erscheinen hier.'**
  String get chatInboxEmptyBody;

  /// Preview shown for a conversation without messages.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten'**
  String get chatNoMessagesYet;

  /// Title of a conversation screen.
  ///
  /// In de, this message translates to:
  /// **'Unterhaltung'**
  String get chatTitle;

  /// Fallback label for a product card in a conversation.
  ///
  /// In de, this message translates to:
  /// **'Produkt'**
  String get chatProductCard;

  /// Hint for the conversation message composer.
  ///
  /// In de, this message translates to:
  /// **'Nachricht schreiben …'**
  String get chatInputHint;

  /// Send message button tooltip.
  ///
  /// In de, this message translates to:
  /// **'Nachricht senden'**
  String get chatSend;

  /// Load older conversation history button.
  ///
  /// In de, this message translates to:
  /// **'Frühere Nachrichten laden'**
  String get chatLoadEarlier;

  /// Menu of secondary product actions.
  ///
  /// In de, this message translates to:
  /// **'Produktaktionen'**
  String get productActionsLabel;

  /// Share this listing.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get productShare;

  /// Text used when sharing a listing.
  ///
  /// In de, this message translates to:
  /// **'{title} – {price} auf DÛKAN'**
  String productShareText({required String title, required String price});

  /// Opens the report listing flow.
  ///
  /// In de, this message translates to:
  /// **'Anzeige melden'**
  String get productReport;

  /// Title of the report reason sheet.
  ///
  /// In de, this message translates to:
  /// **'Warum meldest du diese Anzeige?'**
  String get productReportTitle;

  /// Optional report details field hint.
  ///
  /// In de, this message translates to:
  /// **'Optionale Beschreibung (max. 3000 Zeichen)'**
  String get productReportDetailsHint;

  /// Submits the report.
  ///
  /// In de, this message translates to:
  /// **'Meldung senden'**
  String get productReportSubmit;

  /// Confirmation after a report is filed.
  ///
  /// In de, this message translates to:
  /// **'Danke. Wir prüfen die Meldung.'**
  String get productReportSubmitted;

  /// Report reason: spam.
  ///
  /// In de, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// Report reason: fraud.
  ///
  /// In de, this message translates to:
  /// **'Betrug'**
  String get reportReasonFraud;

  /// Report reason: counterfeit.
  ///
  /// In de, this message translates to:
  /// **'Plagiat / Fälschung'**
  String get reportReasonCounterfeit;

  /// Report reason: prohibited item.
  ///
  /// In de, this message translates to:
  /// **'Verbotener Artikel'**
  String get reportReasonProhibited;

  /// Report reason: harassment.
  ///
  /// In de, this message translates to:
  /// **'Belästigung'**
  String get reportReasonHarassment;

  /// Report reason: inappropriate content.
  ///
  /// In de, this message translates to:
  /// **'Unangemessene Inhalte'**
  String get reportReasonInappropriate;

  /// Report reason: other.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get reportReasonOther;

  /// Badge shown for verified business sellers.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert'**
  String get sellerVerified;

  /// Badge for private sellers.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get sellerTypePrivate;

  /// Badge for business sellers.
  ///
  /// In de, this message translates to:
  /// **'Gewerblich'**
  String get sellerTypeBusiness;

  /// Seller profile listings section title.
  ///
  /// In de, this message translates to:
  /// **'Angebote dieses Verkäufers'**
  String get sellerProfileListingsTitle;

  /// Seller profile about section title.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get sellerProfileAbout;

  /// Shown when a seller has no description.
  ///
  /// In de, this message translates to:
  /// **'Dieser Verkäufer hat noch keine Beschreibung hinterlegt.'**
  String get sellerProfileNoBio;

  /// Empty state for seller listings.
  ///
  /// In de, this message translates to:
  /// **'Aktuell keine Angebote verfügbar.'**
  String get sellerProfileEmptyListings;

  /// Error state for an unavailable seller.
  ///
  /// In de, this message translates to:
  /// **'Verkäufer nicht gefunden.'**
  String get sellerProfileLoadFailed;

  /// Similar listings section title.
  ///
  /// In de, this message translates to:
  /// **'Ähnliche Angebote'**
  String get productSimilarTitle;

  /// Empty state for similar listings.
  ///
  /// In de, this message translates to:
  /// **'Noch keine ähnlichen Angebote.'**
  String get productSimilarEmpty;

  /// More-from-seller section title.
  ///
  /// In de, this message translates to:
  /// **'Weitere Angebote dieses Verkäufers'**
  String get productSellerListingsTitle;

  /// Product details section title.
  ///
  /// In de, this message translates to:
  /// **'Produktdetails'**
  String get productDetailsTitle;

  /// Detail row: condition.
  ///
  /// In de, this message translates to:
  /// **'Zustand'**
  String get productDetailsCondition;

  /// Detail row: category.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get productDetailsCategory;

  /// Detail row: city.
  ///
  /// In de, this message translates to:
  /// **'Stadt'**
  String get productDetailsCity;

  /// Detail row: shipping.
  ///
  /// In de, this message translates to:
  /// **'Versand'**
  String get productDetailsShipping;

  /// Shipping value: free shipping.
  ///
  /// In de, this message translates to:
  /// **'Kostenloser Versand'**
  String get productDetailsFreeShipping;

  /// Shipping value: seller ships.
  ///
  /// In de, this message translates to:
  /// **'Verkäufer versendet'**
  String get productDetailsPaidShipping;

  /// Shipping value: pickup only.
  ///
  /// In de, this message translates to:
  /// **'Nur Abholung'**
  String get productDetailsPickupOnly;

  /// Expand a long description.
  ///
  /// In de, this message translates to:
  /// **'Mehr anzeigen'**
  String get productDescriptionMore;

  /// Collapse a long description.
  ///
  /// In de, this message translates to:
  /// **'Weniger anzeigen'**
  String get productDescriptionLess;

  /// Snack bar after adding a favorite.
  ///
  /// In de, this message translates to:
  /// **'Zu Favoriten hinzugefügt'**
  String get favoriteAdded;

  /// Snack bar after removing a favorite.
  ///
  /// In de, this message translates to:
  /// **'Aus Favoriten entfernt'**
  String get favoriteRemoved;

  /// Semantic label for the tappable seller card.
  ///
  /// In de, this message translates to:
  /// **'Verkäuferprofil ansehen'**
  String get viewSellerProfile;

  /// Title when a listing is unavailable, without assuming it was sold or deleted.
  ///
  /// In de, this message translates to:
  /// **'Anzeige nicht verfügbar'**
  String get productUnavailableTitle;

  /// Body when a listing is unavailable, without claiming a specific cause.
  ///
  /// In de, this message translates to:
  /// **'Diese Anzeige kann derzeit nicht angezeigt werden.'**
  String get productUnavailableBody;

  /// Accessible fallback label for a missing or failed product image.
  ///
  /// In de, this message translates to:
  /// **'Bild nicht verfügbar'**
  String get productImageUnavailable;

  /// Accessible gallery position. Current is the one-based image number; total is the number of images.
  ///
  /// In de, this message translates to:
  /// **'Bild {current} von {total}'**
  String productGalleryPosition({required int current, required int total});

  /// Detail row label for the product brand.
  ///
  /// In de, this message translates to:
  /// **'Marke'**
  String get productDetailsBrand;

  /// Shipping fallback when terms are unknown: arrange privately and directly with the seller. Does not promise shipping availability or imply pickup, fees, or platform-managed delivery.
  ///
  /// In de, this message translates to:
  /// **'Versand direkt mit dem Verkäufer vereinbaren.'**
  String get productShippingArrangement;

  /// Action label to add this listing to favorites, not a success confirmation.
  ///
  /// In de, this message translates to:
  /// **'Zu Favoriten hinzufügen'**
  String get favoriteAddAction;

  /// Action label to remove this listing from favorites, not a success confirmation.
  ///
  /// In de, this message translates to:
  /// **'Aus Favoriten entfernen'**
  String get favoriteRemoveAction;
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
      <String>['ar', 'de', 'en', 'ku', 'tr'].contains(locale.languageCode);

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
    case 'ku':
      return AppLocalizationsKu();
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
