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

  /// Heading above the private and business identity switcher in Account.
  ///
  /// In de, this message translates to:
  /// **'Deine Verkaufsprofile'**
  String get accountSellingProfilesTitle;

  /// Label for the permanent personal identity in the Account switcher.
  ///
  /// In de, this message translates to:
  /// **'Privatperson'**
  String get accountPersonalIdentity;

  /// Account action that starts registration of the one business identity.
  ///
  /// In de, this message translates to:
  /// **'Geschäft registrieren'**
  String get accountRegisterBusiness;

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

  /// Account legal tile that lists third-party data sources and their licenses.
  ///
  /// In de, this message translates to:
  /// **'Datenquellen'**
  String get legalDataSources;

  /// ODbL attribution for OpenStreetMap map tiles and imported directory places. Keep 'OpenStreetMap' and 'Open Database License (ODbL)' untranslated.
  ///
  /// In de, this message translates to:
  /// **'Karten- und Ortsdaten © OpenStreetMap-Mitwirkende, lizenziert unter der Open Database License (ODbL).'**
  String get legalOsmAttribution;

  /// Note on unclaimed directory entries imported from OpenStreetMap (E3 list/detail). Keep 'OpenStreetMap' untranslated.
  ///
  /// In de, this message translates to:
  /// **'Nicht verifiziert · Daten © OpenStreetMap-Mitwirkende'**
  String get directoryUnverifiedOsmNote;

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

  /// Identity owned by the viewer and immutably bound to this chat.
  ///
  /// In de, this message translates to:
  /// **'Als {name}'**
  String chatIdentityContext({required String name});

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

  /// Title shown before the Sell form when both identities exist.
  ///
  /// In de, this message translates to:
  /// **'Verkaufsprofil wählen'**
  String get sellIdentityChoiceTitle;

  /// Explains that one identity must be bound to the whole listing draft.
  ///
  /// In de, this message translates to:
  /// **'Wähle, ob dieses Angebot privat oder geschäftlich veröffentlicht wird.'**
  String get sellIdentityChoiceBody;

  /// Sell choice and bound-draft label for the person identity.
  ///
  /// In de, this message translates to:
  /// **'Als Privatperson'**
  String get sellAsPerson;

  /// Sell choice and bound-draft label for the business identity.
  ///
  /// In de, this message translates to:
  /// **'Als Geschäft'**
  String get sellAsBusiness;

  /// Tooltip that returns to identity choice and resets the current draft.
  ///
  /// In de, this message translates to:
  /// **'Verkaufsprofil wechseln'**
  String get sellChangeIdentity;

  /// Heading for listings owned by the person's private seller identity.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get myListingsPrivateSection;

  /// Heading for listings owned by the business seller identity.
  ///
  /// In de, this message translates to:
  /// **'Geschäft'**
  String get myListingsBusinessSection;

  /// Empty message inside one identity section of My Listings.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Angebote in diesem Bereich.'**
  String get myListingsSectionEmpty;

  /// Title of the catalog-first Sell step.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du verkaufen?'**
  String get sellCatalogTitle;

  /// Explains catalog templates and free-form entry.
  ///
  /// In de, this message translates to:
  /// **'Suche zuerst nach einem ähnlichen Artikel oder starte ohne Vorlage.'**
  String get sellCatalogBody;

  /// Hint for catalog template search.
  ///
  /// In de, this message translates to:
  /// **'Katalog durchsuchen'**
  String get sellCatalogSearchHint;

  /// Action to apply a catalog template.
  ///
  /// In de, this message translates to:
  /// **'Vorlage verwenden'**
  String get sellCatalogUseTemplate;

  /// Action to begin a listing without a template.
  ///
  /// In de, this message translates to:
  /// **'Ohne Vorlage starten'**
  String get sellFreeForm;

  /// Empty-state title when catalog search has no match.
  ///
  /// In de, this message translates to:
  /// **'Keine passende Vorlage'**
  String get sellNoTemplatesTitle;

  /// Empty-state body offering free-form listing entry.
  ///
  /// In de, this message translates to:
  /// **'Du kannst dein Angebot frei eingeben.'**
  String get sellNoTemplatesBody;

  /// Title of the listing details step.
  ///
  /// In de, this message translates to:
  /// **'Angebotsdetails'**
  String get sellDetailsTitle;

  /// Label for private or business seller kind.
  ///
  /// In de, this message translates to:
  /// **'Verkäuferart'**
  String get sellSellerKindLabel;

  /// Private seller option.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get sellSellerPrivate;

  /// Business seller option.
  ///
  /// In de, this message translates to:
  /// **'Gewerblich'**
  String get sellSellerBusiness;

  /// Label for the seller display name.
  ///
  /// In de, this message translates to:
  /// **'Anzeigename'**
  String get sellSellerNameLabel;

  /// Label for the listing title.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get sellListingTitleLabel;

  /// Label for listing price in euros.
  ///
  /// In de, this message translates to:
  /// **'Preis in Euro'**
  String get sellPriceLabel;

  /// Label for the German listing city.
  ///
  /// In de, this message translates to:
  /// **'Stadt'**
  String get sellCityLabel;

  /// Label for listing category.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get sellCategoryLabel;

  /// Label for listing condition.
  ///
  /// In de, this message translates to:
  /// **'Zustand'**
  String get sellConditionLabel;

  /// Label for listing description.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get sellDescriptionLabel;

  /// Title of the listing photo step.
  ///
  /// In de, this message translates to:
  /// **'Fotos'**
  String get sellPhotosTitle;

  /// Explains listing photo count and compression.
  ///
  /// In de, this message translates to:
  /// **'Füge 1 bis 10 Fotos hinzu. Bilder werden vor dem Upload komprimiert.'**
  String get sellPhotosBody;

  /// Action to choose listing photos from the library.
  ///
  /// In de, this message translates to:
  /// **'Fotos auswählen'**
  String get sellPickPhotos;

  /// Action to capture a listing photo.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get sellTakePhoto;

  /// Maximum listing photo count message.
  ///
  /// In de, this message translates to:
  /// **'Maximal 10 Fotos'**
  String get sellPhotoLimit;

  /// Error when a listing photo cannot be processed.
  ///
  /// In de, this message translates to:
  /// **'Das Foto konnte nicht verarbeitet werden.'**
  String get sellPhotoFailed;

  /// Title of the listing review step.
  ///
  /// In de, this message translates to:
  /// **'Prüfen und senden'**
  String get sellReviewTitle;

  /// Action that submits a listing for moderation.
  ///
  /// In de, this message translates to:
  /// **'Zur Prüfung einreichen'**
  String get sellSubmit;

  /// Required listing field validation error.
  ///
  /// In de, this message translates to:
  /// **'Dieses Feld ist erforderlich.'**
  String get sellValidationRequired;

  /// Invalid listing price validation error.
  ///
  /// In de, this message translates to:
  /// **'Gib einen gültigen Preis größer als 0 ein.'**
  String get sellValidationPrice;

  /// Invalid listing description validation error.
  ///
  /// In de, this message translates to:
  /// **'Die Beschreibung muss mindestens 10 Zeichen haben.'**
  String get sellValidationDescription;

  /// Missing listing photo validation error.
  ///
  /// In de, this message translates to:
  /// **'Füge mindestens ein Foto hinzu.'**
  String get sellValidationPhotos;

  /// Title after a listing enters pending review.
  ///
  /// In de, this message translates to:
  /// **'Angebot wird geprüft'**
  String get sellConfirmationTitle;

  /// Explains that a submitted listing is not public yet.
  ///
  /// In de, this message translates to:
  /// **'Dein Angebot wurde eingereicht und ist noch nicht öffentlich. Wir benachrichtigen dich nach der Prüfung.'**
  String get sellConfirmationBody;

  /// Action to open the current user's listings.
  ///
  /// In de, this message translates to:
  /// **'Meine Angebote anzeigen'**
  String get sellViewMyListings;

  /// Action to reset and create another listing.
  ///
  /// In de, this message translates to:
  /// **'Weiteres Angebot erstellen'**
  String get sellCreateAnother;

  /// Confirmation that a catalog template was applied.
  ///
  /// In de, this message translates to:
  /// **'Vorlage übernommen. Prüfe alle Angaben vor dem Senden.'**
  String get sellTemplateImported;

  /// Title of the authenticated user's listing status screen.
  ///
  /// In de, this message translates to:
  /// **'Meine Angebote'**
  String get myListingsTitle;

  /// Empty-state title for My Listings.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Angebote'**
  String get myListingsEmptyTitle;

  /// Empty-state body for My Listings.
  ///
  /// In de, this message translates to:
  /// **'Deine eingereichten Angebote und ihr Prüfstatus erscheinen hier.'**
  String get myListingsEmptyBody;

  /// Public label for pending_review listing status.
  ///
  /// In de, this message translates to:
  /// **'Wird geprüft'**
  String get listingStatusPending;

  /// Public label for active listing status.
  ///
  /// In de, this message translates to:
  /// **'Veröffentlicht'**
  String get listingStatusActive;

  /// Public label for rejected listing status.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get listingStatusRejected;

  /// Public label for draft listing status.
  ///
  /// In de, this message translates to:
  /// **'Entwurf'**
  String get listingStatusDraft;

  /// Public label for sold listing status.
  ///
  /// In de, this message translates to:
  /// **'Verkauft'**
  String get listingStatusSold;

  /// Public label for blocked listing status.
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get listingStatusBlocked;

  /// Label for a listing moderation reason.
  ///
  /// In de, this message translates to:
  /// **'Grund'**
  String get listingModerationReason;

  /// Account menu action for My Listings.
  ///
  /// In de, this message translates to:
  /// **'Meine Angebote'**
  String get accountMyListings;

  /// Account menu action for admin moderation.
  ///
  /// In de, this message translates to:
  /// **'Moderation'**
  String get accountModeration;

  /// Title of the admin listing moderation queue.
  ///
  /// In de, this message translates to:
  /// **'Angebote prüfen'**
  String get moderationTitle;

  /// Label for pending moderation count.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get moderationPending;

  /// Label for listings approved today count.
  ///
  /// In de, this message translates to:
  /// **'Heute freigegeben'**
  String get moderationApprovedToday;

  /// Label for listings rejected today count.
  ///
  /// In de, this message translates to:
  /// **'Heute abgelehnt'**
  String get moderationRejectedToday;

  /// Empty-state title for the moderation queue.
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Angebote'**
  String get moderationEmptyTitle;

  /// Empty-state body for the moderation queue.
  ///
  /// In de, this message translates to:
  /// **'Neue Einreichungen erscheinen automatisch hier.'**
  String get moderationEmptyBody;

  /// Admin action to approve a listing.
  ///
  /// In de, this message translates to:
  /// **'Freigeben'**
  String get moderationApprove;

  /// Admin action to reject a listing.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get moderationReject;

  /// Label for optional listing rejection feedback.
  ///
  /// In de, this message translates to:
  /// **'Grund (optional)'**
  String get moderationReasonLabel;

  /// Hint for optional listing rejection feedback.
  ///
  /// In de, this message translates to:
  /// **'Kurze Rückmeldung an den Verkäufer'**
  String get moderationReasonHint;

  /// Confirmation after an admin approves a listing.
  ///
  /// In de, this message translates to:
  /// **'Das Angebot ist jetzt öffentlich.'**
  String get moderationApproveSuccess;

  /// Confirmation after an admin rejects a listing.
  ///
  /// In de, this message translates to:
  /// **'Das Angebot wurde abgelehnt.'**
  String get moderationRejectSuccess;

  /// Title when a non-admin opens moderation.
  ///
  /// In de, this message translates to:
  /// **'Nur für Administratoren'**
  String get moderationForbiddenTitle;

  /// Body when a non-admin opens moderation.
  ///
  /// In de, this message translates to:
  /// **'Du hast keinen Zugriff auf die Moderationswarteschlange.'**
  String get moderationForbiddenBody;

  /// Label for listing submission date in moderation.
  ///
  /// In de, this message translates to:
  /// **'Eingereicht'**
  String get moderationSubmittedLabel;

  /// Label for seller identity in moderation.
  ///
  /// In de, this message translates to:
  /// **'Verkäufer'**
  String get moderationSellerLabel;

  /// Label for category in moderation.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get moderationCategoryLabel;

  /// Error when an admin decision cannot be saved.
  ///
  /// In de, this message translates to:
  /// **'Die Entscheidung konnte nicht gespeichert werden.'**
  String get moderationDecisionFailed;

  /// Title when a public profile does not exist.
  ///
  /// In de, this message translates to:
  /// **'Profil nicht gefunden'**
  String get profileNotFoundTitle;

  /// Body when a public profile does not exist.
  ///
  /// In de, this message translates to:
  /// **'Dieses Profil ist nicht verfügbar.'**
  String get profileNotFoundBody;

  /// Fallback display name when a profile has none.
  ///
  /// In de, this message translates to:
  /// **'Zêrîn-Mitglied'**
  String get profileFallbackName;

  /// Number of active listings on a profile.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Angebote} =1{1 Angebot} other{{count} Angebote}}'**
  String profileListingCount({required int count});

  /// Heading for a profile bio section.
  ///
  /// In de, this message translates to:
  /// **'Über mich'**
  String get profileAboutTitle;

  /// Placeholder when a profile has no bio.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Beschreibung.'**
  String get profileNoBio;

  /// Heading for a profile's active listings.
  ///
  /// In de, this message translates to:
  /// **'Aktive Angebote'**
  String get profileListingsTitle;

  /// Empty state for a profile with no active listings.
  ///
  /// In de, this message translates to:
  /// **'Zurzeit keine aktiven Angebote.'**
  String get profileNoListings;

  /// CTA to message a profile through chat.
  ///
  /// In de, this message translates to:
  /// **'Nachricht senden'**
  String get profileSendMessage;

  /// Title of the edit profile screen.
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get editProfileTitle;

  /// Button to change the profile photo.
  ///
  /// In de, this message translates to:
  /// **'Profilbild ändern'**
  String get profileEditAvatar;

  /// Pick avatar from the photo library.
  ///
  /// In de, this message translates to:
  /// **'Aus Galerie wählen'**
  String get profileAvatarFromGallery;

  /// Capture avatar from the camera.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get profileAvatarFromCamera;

  /// Remove the current profile photo.
  ///
  /// In de, this message translates to:
  /// **'Profilbild entfernen'**
  String get profileAvatarRemove;

  /// Error when avatar upload or removal fails.
  ///
  /// In de, this message translates to:
  /// **'Das Profilbild konnte nicht gespeichert werden.'**
  String get profileAvatarError;

  /// Label for the display name field.
  ///
  /// In de, this message translates to:
  /// **'Anzeigename'**
  String get profileDisplayNameLabel;

  /// Validation error for the display name.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen mit 1 bis 80 Zeichen ein.'**
  String get profileDisplayNameInvalid;

  /// Label for the username field.
  ///
  /// In de, this message translates to:
  /// **'Benutzername'**
  String get profileUsernameLabel;

  /// Helper text describing username rules.
  ///
  /// In de, this message translates to:
  /// **'3–30 Zeichen: Kleinbuchstaben, Ziffern und Unterstriche.'**
  String get profileUsernameHelper;

  /// Username conflict error.
  ///
  /// In de, this message translates to:
  /// **'Dieser Benutzername ist bereits vergeben.'**
  String get profileUsernameTaken;

  /// Reserved username error.
  ///
  /// In de, this message translates to:
  /// **'Dieser Benutzername ist reserviert.'**
  String get profileUsernameReserved;

  /// Invalid username error.
  ///
  /// In de, this message translates to:
  /// **'Dieser Benutzername ist ungültig.'**
  String get profileUsernameInvalid;

  /// Label for the profile city dropdown.
  ///
  /// In de, this message translates to:
  /// **'Stadt'**
  String get profileCityLabel;

  /// Error when no city is selected.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle eine Stadt aus.'**
  String get profileCityRequired;

  /// Error for an unsupported city.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle eine unterstützte deutsche Stadt.'**
  String get profileCityInvalid;

  /// Label for the bio field.
  ///
  /// In de, this message translates to:
  /// **'Über mich'**
  String get profileBioLabel;

  /// Hint for the bio field.
  ///
  /// In de, this message translates to:
  /// **'Erzähl kurz etwas über dich.'**
  String get profileBioHint;

  /// Error when the bio exceeds the limit.
  ///
  /// In de, this message translates to:
  /// **'Die Beschreibung darf höchstens 500 Zeichen enthalten.'**
  String get profileBioTooLong;

  /// Save the profile.
  ///
  /// In de, this message translates to:
  /// **'Profil speichern'**
  String get profileSave;

  /// Success message after saving the profile.
  ///
  /// In de, this message translates to:
  /// **'Profil gespeichert.'**
  String get profileSaved;

  /// Title of the favorites screen.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get favoritesTitle;

  /// Empty favorites title.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Favoriten'**
  String get favoritesEmptyTitle;

  /// Empty favorites body.
  ///
  /// In de, this message translates to:
  /// **'Angebote, die du speicherst, erscheinen hier.'**
  String get favoritesEmptyBody;

  /// Title of the recently viewed screen.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt angesehen'**
  String get recentlyViewedTitle;

  /// Empty recently viewed title.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts angesehen'**
  String get recentlyViewedEmptyTitle;

  /// Empty recently viewed body.
  ///
  /// In de, this message translates to:
  /// **'Angebote, die du ansiehst, erscheinen hier.'**
  String get recentlyViewedEmptyBody;

  /// Account action to edit the profile.
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get accountEditProfile;

  /// Account action to view the public profile.
  ///
  /// In de, this message translates to:
  /// **'Öffentliches Profil'**
  String get accountViewPublicProfile;

  /// Subtitle when the signed-in user has no username yet.
  ///
  /// In de, this message translates to:
  /// **'Profil vervollständigen'**
  String get accountProfileIncomplete;

  /// Title of the marketplace map screen.
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get mapTitle;

  /// Tooltip for actions that open the map.
  ///
  /// In de, this message translates to:
  /// **'Karte öffnen'**
  String get mapOpenTooltip;

  /// Action to center the map on the viewer's transient location.
  ///
  /// In de, this message translates to:
  /// **'Meinen Standort verwenden'**
  String get mapUseMyLocation;

  /// Action to retry the foreground location request.
  ///
  /// In de, this message translates to:
  /// **'Standort erneut versuchen'**
  String get mapRetryLocation;

  /// Privacy explanation for viewer location.
  ///
  /// In de, this message translates to:
  /// **'Dein Standort wird nur zum Zentrieren der Karte verwendet und nicht gespeichert.'**
  String get mapLocationPrivacy;

  /// Fallback when foreground location permission is denied.
  ///
  /// In de, this message translates to:
  /// **'Standortzugriff abgelehnt. Wähle stattdessen eine Stadt.'**
  String get mapLocationDenied;

  /// Fallback when location permission is permanently denied.
  ///
  /// In de, this message translates to:
  /// **'Standortzugriff ist deaktiviert. Wähle eine Stadt oder ändere die Berechtigung in den Einstellungen.'**
  String get mapLocationDeniedForever;

  /// Fallback when device location services are disabled.
  ///
  /// In de, this message translates to:
  /// **'Ortungsdienste sind ausgeschaltet. Wähle stattdessen eine Stadt.'**
  String get mapLocationServiceDisabled;

  /// Fallback when a foreground position cannot be obtained.
  ///
  /// In de, this message translates to:
  /// **'Dein Standort ist gerade nicht verfügbar. Wähle stattdessen eine Stadt.'**
  String get mapLocationUnavailable;

  /// Action to choose a manual map center city.
  ///
  /// In de, this message translates to:
  /// **'Stadt wählen'**
  String get mapChooseCity;

  /// Search hint in the manual city picker.
  ///
  /// In de, this message translates to:
  /// **'Stadt suchen'**
  String get mapCitySearchHint;

  /// Label when the map uses the viewer's location.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Standort'**
  String get mapCenterCurrent;

  /// Label for a manually selected map center.
  ///
  /// In de, this message translates to:
  /// **'Zentrum: {city}'**
  String mapCenterCity({required String city});

  /// Label for map radius controls.
  ///
  /// In de, this message translates to:
  /// **'Umkreis'**
  String get mapRadiusLabel;

  /// Radius option with no distance limit.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get mapRadiusAll;

  /// Title of the shared map filter sheet.
  ///
  /// In de, this message translates to:
  /// **'Kartenfilter'**
  String get mapFiltersTitle;

  /// Tooltip for the map filter action.
  ///
  /// In de, this message translates to:
  /// **'Angebote filtern'**
  String get mapFiltersTooltip;

  /// Category field in the map filter sheet.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get mapCategoryLabel;

  /// Map filter option with no category restriction.
  ///
  /// In de, this message translates to:
  /// **'Alle Kategorien'**
  String get mapCategoryAll;

  /// Map filter option with no condition restriction.
  ///
  /// In de, this message translates to:
  /// **'Alle Zustände'**
  String get mapConditionAll;

  /// Minimum price field in euros.
  ///
  /// In de, this message translates to:
  /// **'Mindestpreis (€)'**
  String get mapPriceMin;

  /// Maximum price field in euros.
  ///
  /// In de, this message translates to:
  /// **'Höchstpreis (€)'**
  String get mapPriceMax;

  /// Validation error for map price filters.
  ///
  /// In de, this message translates to:
  /// **'Gib gültige Preise ein; der Mindestpreis darf nicht höher sein.'**
  String get mapPriceInvalid;

  /// Visible listing count on the map.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Angebote auf der Karte} =1{1 Angebot auf der Karte} other{{count} Angebote auf der Karte}}'**
  String mapListingsCount({required int count});

  /// Map empty-state title.
  ///
  /// In de, this message translates to:
  /// **'Keine Angebote in diesem Umkreis'**
  String get mapEmptyTitle;

  /// Map empty-state body.
  ///
  /// In de, this message translates to:
  /// **'Vergrößere den Umkreis, verschiebe das Zentrum oder passe die Filter an.'**
  String get mapEmptyBody;

  /// Map marker loading message.
  ///
  /// In de, this message translates to:
  /// **'Angebote in der Nähe werden geladen …'**
  String get mapLoading;

  /// Accessible label for one map pin.
  ///
  /// In de, this message translates to:
  /// **'{title}, {city}'**
  String mapPinSemantic({required String title, required String city});

  /// Accessible label for a marker cluster.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Angebot} other{{count} Angebote}}'**
  String mapClusterSemantic({required int count});

  /// Privacy label for a city-jittered listing pin.
  ///
  /// In de, this message translates to:
  /// **'Ungefährer Standort zum Schutz privater Verkäufer'**
  String get mapApproximateLocation;

  /// Label for a verified opted-in business pin.
  ///
  /// In de, this message translates to:
  /// **'Genauer Standort eines verifizierten Geschäfts'**
  String get mapPreciseStoreLocation;

  /// Action to open external directions for a verified store.
  ///
  /// In de, this message translates to:
  /// **'Route berechnen'**
  String get mapDirections;

  /// Error when external directions cannot be opened.
  ///
  /// In de, this message translates to:
  /// **'Die Route konnte nicht geöffnet werden.'**
  String get mapDirectionsFailed;

  /// Action from a map preview to the existing listing detail.
  ///
  /// In de, this message translates to:
  /// **'Angebot öffnen'**
  String get mapOpenListing;

  /// Error when the moderation overview fails to load.
  ///
  /// In de, this message translates to:
  /// **'Moderation konnte nicht geladen werden.'**
  String get moderationLoadFailed;

  /// Shown when a non-admin user reaches the moderation screen.
  ///
  /// In de, this message translates to:
  /// **'Administratorzugriff erforderlich.'**
  String get moderationAdminRequired;

  /// Tab label for the admin overview.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get moderationTabOverview;

  /// Tab label for the listings moderation queue.
  ///
  /// In de, this message translates to:
  /// **'Angebote'**
  String get moderationTabListings;

  /// Tab label for the seller verification queue.
  ///
  /// In de, this message translates to:
  /// **'Verkäuferprüfung'**
  String get moderationTabVerification;

  /// Tab label for the reports queue.
  ///
  /// In de, this message translates to:
  /// **'Meldungen'**
  String get moderationTabReports;

  /// Overview card title for pending listings count.
  ///
  /// In de, this message translates to:
  /// **'Offene Angebote'**
  String get moderationOverviewPendingListings;

  /// Overview card title for pending seller documents count.
  ///
  /// In de, this message translates to:
  /// **'Offene Verkäuferdokumente'**
  String get moderationOverviewPendingDocuments;

  /// Overview card title for open reports count.
  ///
  /// In de, this message translates to:
  /// **'Offene Meldungen'**
  String get moderationOverviewOpenReports;

  /// Error when the listings queue fails to load.
  ///
  /// In de, this message translates to:
  /// **'Angebote konnten nicht geladen werden.'**
  String get moderationListingsLoadFailed;

  /// Empty state for the listings moderation queue.
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Angebote.'**
  String get moderationListingsEmpty;

  /// Error when the seller verification queue fails to load.
  ///
  /// In de, this message translates to:
  /// **'Verkäuferdokumente konnten nicht geladen werden.'**
  String get moderationDocumentsLoadFailed;

  /// Empty state for the seller verification queue.
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Verkäuferdokumente.'**
  String get moderationDocumentsEmpty;

  /// Action to open a seller document.
  ///
  /// In de, this message translates to:
  /// **'Dokument öffnen'**
  String get moderationOpenDocument;

  /// Label for a doctor's approved professional verification document.
  ///
  /// In de, this message translates to:
  /// **'Approbation / Kammernachweis'**
  String get moderationDocumentKindMedicalProfessionalRegistration;

  /// Seller label in a report card.
  ///
  /// In de, this message translates to:
  /// **'Verkäufer: {shopName}'**
  String moderationReportSeller({required String shopName});

  /// Action to dismiss a report without action.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get moderationReportDismiss;

  /// Action to block a reported listing.
  ///
  /// In de, this message translates to:
  /// **'Angebot sperren'**
  String get moderationReportBlock;

  /// Title of the block-listing confirmation dialog.
  ///
  /// In de, this message translates to:
  /// **'Dieses Angebot sperren?'**
  String get moderationBlockConfirmTitle;

  /// Body of the block-listing confirmation dialog.
  ///
  /// In de, this message translates to:
  /// **'Dies sperrt {title} und löst diese Meldung.'**
  String moderationBlockConfirmBody({required String title});

  /// Confirm action in the block-listing dialog.
  ///
  /// In de, this message translates to:
  /// **'Sperren'**
  String get moderationBlockConfirmAction;

  /// Title of the rejection reason dialog.
  ///
  /// In de, this message translates to:
  /// **'Ablehnungsgrund'**
  String get moderationRejectionReasonTitle;

  /// Fallback title when a reported listing title is unavailable.
  ///
  /// In de, this message translates to:
  /// **'das gemeldete Angebot'**
  String get moderationReportFallbackTarget;

  /// Confirmation after a document moderation decision is saved.
  ///
  /// In de, this message translates to:
  /// **'Dokumententscheidung gespeichert.'**
  String get moderationDocumentSaved;

  /// Error when a document moderation decision fails.
  ///
  /// In de, this message translates to:
  /// **'Entscheidung fehlgeschlagen.'**
  String get moderationDocumentFailed;

  /// Confirmation after a report is resolved.
  ///
  /// In de, this message translates to:
  /// **'Meldung bearbeitet.'**
  String get moderationReportResolved;

  /// Error when a report action fails.
  ///
  /// In de, this message translates to:
  /// **'Aktion fehlgeschlagen.'**
  String get moderationReportActionFailed;

  /// Fallback when a report target has no title.
  ///
  /// In de, this message translates to:
  /// **'Gemeldetes Ziel nicht verfügbar'**
  String get moderationReportTargetUnavailable;

  /// Error when the reports queue fails to load.
  ///
  /// In de, this message translates to:
  /// **'Meldungen konnten nicht geladen werden.'**
  String get moderationReportsLoadFailed;

  /// Error when a signed document URL cannot be opened.
  ///
  /// In de, this message translates to:
  /// **'Das Dokument konnte nicht geöffnet werden.'**
  String get moderationDocumentOpenFailed;

  /// Empty state for the reports queue.
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Meldungen.'**
  String get moderationReportsEmpty;

  /// Label for the optional compare-at price field.
  ///
  /// In de, this message translates to:
  /// **'Originalpreis in Euro (optional)'**
  String get sellCompareAtPriceLabel;

  /// Hint for the optional compare-at price field.
  ///
  /// In de, this message translates to:
  /// **'Durchgestrichener Preis neben deinem Preis'**
  String get sellCompareAtPriceHint;

  /// Validation error when compare-at price is not greater than price.
  ///
  /// In de, this message translates to:
  /// **'Der Originalpreis muss höher als dein Preis sein.'**
  String get sellValidationCompareAtPrice;

  /// Visible OpenStreetMap tile attribution.
  ///
  /// In de, this message translates to:
  /// **'© OpenStreetMap-Mitwirkende'**
  String get mapOsmAttribution;

  /// Title of the owner hub for directory businesses and the Account entry.
  ///
  /// In de, this message translates to:
  /// **'Mein Unternehmen'**
  String get businessHubTitle;

  /// Subtitle of the Account entry that opens the owner hub.
  ///
  /// In de, this message translates to:
  /// **'Restaurant, Café, Imbiss oder Arztpraxis eintragen'**
  String get businessAccountEntrySubtitle;

  /// Title of the card that starts a directory listing.
  ///
  /// In de, this message translates to:
  /// **'Unternehmen eintragen'**
  String get businessStartTitle;

  /// Explains that the type decides the required documents.
  ///
  /// In de, this message translates to:
  /// **'Wähle zuerst die Art deines Eintrags. Danach siehst du genau, welche Nachweise wir dafür brauchen.'**
  String get businessStartBody;

  /// Label of the directory type choice.
  ///
  /// In de, this message translates to:
  /// **'Art des Eintrags'**
  String get businessTypeLabel;

  /// Label of the business name field.
  ///
  /// In de, this message translates to:
  /// **'Name des Unternehmens'**
  String get businessNameLabel;

  /// Button that creates the business and opens the documents screen.
  ///
  /// In de, this message translates to:
  /// **'Weiter zu den Nachweisen'**
  String get businessStartAction;

  /// Title shown to private sellers, who cannot join the directory.
  ///
  /// In de, this message translates to:
  /// **'Privates Verkaufskonto'**
  String get businessPrivateSellerTitle;

  /// Explains why private sellers cannot join the directory.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto verkauft als Privatperson. Einträge im Verzeichnis sind nur mit einem Geschäftskonto möglich. Bitte wende dich an den Support.'**
  String get businessPrivateSellerBody;

  /// Owner hub status: documents approved and verified.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert'**
  String get businessStatusVerified;

  /// Owner hub status: all required documents uploaded, waiting for review.
  ///
  /// In de, this message translates to:
  /// **'In Prüfung'**
  String get businessStatusInReview;

  /// Owner hub status: at least one required document is missing or rejected.
  ///
  /// In de, this message translates to:
  /// **'Nachweise fehlen'**
  String get businessStatusDocumentsMissing;

  /// Title of the verification documents screen and hub tile.
  ///
  /// In de, this message translates to:
  /// **'Nachweise'**
  String get businessDocumentsTile;

  /// Number of approved required documents.
  ///
  /// In de, this message translates to:
  /// **'{approved} von {total} freigegeben'**
  String businessDocumentsProgress({required int approved, required int total});

  /// Title of the directory profile editor and hub tile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get businessProfileTile;

  /// Hub subtitle when no directory profile exists yet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht angelegt'**
  String get businessProfileMissing;

  /// Hub subtitle for an unpublished profile.
  ///
  /// In de, this message translates to:
  /// **'Entwurf – nicht öffentlich'**
  String get businessProfileDraft;

  /// Hub subtitle for a published profile.
  ///
  /// In de, this message translates to:
  /// **'Veröffentlicht'**
  String get businessProfilePublished;

  /// Title of the opening hours editor and hub tile.
  ///
  /// In de, this message translates to:
  /// **'Öffnungszeiten'**
  String get businessHoursTile;

  /// Number of weekly opening intervals.
  ///
  /// In de, this message translates to:
  /// **'{count} Zeitfenster'**
  String businessHoursSummary({required int count});

  /// Title of the menu editor and hub tile.
  ///
  /// In de, this message translates to:
  /// **'Speisekarte'**
  String get businessMenuTile;

  /// Menu size summary.
  ///
  /// In de, this message translates to:
  /// **'{sections} Bereiche · {items} Gerichte'**
  String businessMenuSummary({required int sections, required int items});

  /// Shown on hub tiles that need an existing profile.
  ///
  /// In de, this message translates to:
  /// **'Lege zuerst dein Profil an.'**
  String get businessNeedsProfileFirst;

  /// Label of the publish switch.
  ///
  /// In de, this message translates to:
  /// **'Im Verzeichnis anzeigen'**
  String get businessPublishTitle;

  /// Why the publish switch is disabled before verification.
  ///
  /// In de, this message translates to:
  /// **'Veröffentlichen ist möglich, sobald deine Nachweise freigegeben sind.'**
  String get businessPublishHintUnverified;

  /// Publish switch helper when published.
  ///
  /// In de, this message translates to:
  /// **'Dein Eintrag ist öffentlich sichtbar.'**
  String get businessPublishOn;

  /// Publish switch helper when unpublished.
  ///
  /// In de, this message translates to:
  /// **'Dein Eintrag ist nur für dich sichtbar.'**
  String get businessPublishOff;

  /// Hub note that editors work as drafts before verification.
  ///
  /// In de, this message translates to:
  /// **'Profil, Öffnungszeiten und Speisekarte kannst du schon als Entwurf vorbereiten.'**
  String get businessDraftNote;

  /// Directory type label.
  ///
  /// In de, this message translates to:
  /// **'Restaurant'**
  String get directoryTypeRestaurant;

  /// Directory type label.
  ///
  /// In de, this message translates to:
  /// **'Café'**
  String get directoryTypeCafe;

  /// Directory type label for fast food (the "Imbiss" chip in E3).
  ///
  /// In de, this message translates to:
  /// **'Imbiss'**
  String get directoryTypeFastFood;

  /// Directory type label.
  ///
  /// In de, this message translates to:
  /// **'Arztpraxis'**
  String get directoryTypeDoctor;

  /// Intro of the documents screen. {type} is a directory type label.
  ///
  /// In de, this message translates to:
  /// **'Für einen Eintrag als {type} brauchen wir diese Nachweise. Nur das Zêrîn-Team sieht deine Dokumente.'**
  String businessDocumentsIntro({required String type});

  /// Accepted document formats.
  ///
  /// In de, this message translates to:
  /// **'Foto oder PDF, höchstens 15 MB.'**
  String get businessDocumentsFormats;

  /// Shown when the type is fixed by an existing profile.
  ///
  /// In de, this message translates to:
  /// **'Die Art kannst du jetzt nur noch im Profil ändern.'**
  String get businessTypeLockedHint;

  /// Seller document kind: identity.
  ///
  /// In de, this message translates to:
  /// **'Personalausweis oder Reisepass'**
  String get documentKindIdentity;

  /// What a good identity upload looks like.
  ///
  /// In de, this message translates to:
  /// **'Gut lesbar, alle Ecken sichtbar.'**
  String get documentKindIdentityHint;

  /// Seller document kind: business registration.
  ///
  /// In de, this message translates to:
  /// **'Gewerbeanmeldung oder Handelsregisterauszug'**
  String get documentKindBusinessRegistration;

  /// What a good business registration upload looks like.
  ///
  /// In de, this message translates to:
  /// **'Auf den Namen deines Unternehmens.'**
  String get documentKindBusinessRegistrationHint;

  /// What a good medical registration upload looks like.
  ///
  /// In de, this message translates to:
  /// **'Approbationsurkunde oder Nachweis der Ärztekammer.'**
  String get documentKindMedicalHint;

  /// Document status: not uploaded yet.
  ///
  /// In de, this message translates to:
  /// **'Fehlt'**
  String get documentStatusMissing;

  /// Document status: waiting for admin review.
  ///
  /// In de, this message translates to:
  /// **'In Prüfung'**
  String get documentStatusPending;

  /// Document status: approved.
  ///
  /// In de, this message translates to:
  /// **'Freigegeben'**
  String get documentStatusApproved;

  /// Document status: rejected.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get documentStatusRejected;

  /// Admin rejection note shown to the owner.
  ///
  /// In de, this message translates to:
  /// **'Hinweis des Teams: {note}'**
  String documentRejectionNote({required String note});

  /// Upload a missing document.
  ///
  /// In de, this message translates to:
  /// **'Hochladen'**
  String get documentUploadAction;

  /// Upload a replacement after rejection.
  ///
  /// In de, this message translates to:
  /// **'Neu hochladen'**
  String get documentReuploadAction;

  /// Withdraw a pending document.
  ///
  /// In de, this message translates to:
  /// **'Zurückziehen'**
  String get documentWithdrawAction;

  /// Upload source: camera.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get documentSourceCamera;

  /// Upload source: photo library.
  ///
  /// In de, this message translates to:
  /// **'Foto aus der Galerie'**
  String get documentSourceGallery;

  /// Upload source: PDF file.
  ///
  /// In de, this message translates to:
  /// **'PDF auswählen'**
  String get documentSourcePdf;

  /// Snackbar after a successful upload.
  ///
  /// In de, this message translates to:
  /// **'Hochgeladen. Wir prüfen den Nachweis.'**
  String get documentUploaded;

  /// Snackbar after withdrawing a document.
  ///
  /// In de, this message translates to:
  /// **'Nachweis zurückgezogen.'**
  String get documentWithdrawn;

  /// Upload date of a document.
  ///
  /// In de, this message translates to:
  /// **'Hochgeladen am {date}'**
  String documentUploadedAt({required String date});

  /// Business name validation error.
  ///
  /// In de, this message translates to:
  /// **'Der Name muss 2 bis 100 Zeichen lang sein.'**
  String get businessErrorName;

  /// City validation error.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle eine Stadt aus der Liste.'**
  String get businessErrorCity;

  /// Error when a pending document of the same kind exists.
  ///
  /// In de, this message translates to:
  /// **'Für diesen Nachweis wartet schon ein Dokument auf die Prüfung.'**
  String get businessErrorDocumentPending;

  /// Error for oversized uploads.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist größer als 15 MB.'**
  String get businessErrorFileTooLarge;

  /// Generic validation error from the server.
  ///
  /// In de, this message translates to:
  /// **'Bitte prüfe deine Angaben.'**
  String get businessErrorInvalid;

  /// Label of the cover image section.
  ///
  /// In de, this message translates to:
  /// **'Titelbild'**
  String get businessCoverLabel;

  /// Button that picks a cover image.
  ///
  /// In de, this message translates to:
  /// **'Titelbild wählen'**
  String get businessCoverAction;

  /// Label of the profile description field.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get businessDescriptionLabel;

  /// Helper of the description field.
  ///
  /// In de, this message translates to:
  /// **'20 bis 3000 Zeichen'**
  String get businessDescriptionHelper;

  /// Label of the phone field.
  ///
  /// In de, this message translates to:
  /// **'Telefon'**
  String get businessPhoneLabel;

  /// Label of the website field.
  ///
  /// In de, this message translates to:
  /// **'Website (optional)'**
  String get businessWebsiteLabel;

  /// Helper of the website field.
  ///
  /// In de, this message translates to:
  /// **'Beginnt mit https://'**
  String get businessWebsiteHelper;

  /// Label of the spoken languages choice.
  ///
  /// In de, this message translates to:
  /// **'Gesprochene Sprachen'**
  String get businessLanguagesLabel;

  /// Label of the cuisines choice.
  ///
  /// In de, this message translates to:
  /// **'Küche'**
  String get businessCuisinesLabel;

  /// Label of the price level choice.
  ///
  /// In de, this message translates to:
  /// **'Preisniveau'**
  String get businessPriceLevelLabel;

  /// Label of the diet options.
  ///
  /// In de, this message translates to:
  /// **'Ernährung'**
  String get businessDietLabel;

  /// Diet option: halal.
  ///
  /// In de, this message translates to:
  /// **'Halal'**
  String get businessHalal;

  /// Diet option: vegetarian dishes.
  ///
  /// In de, this message translates to:
  /// **'Vegetarische Gerichte'**
  String get businessVegetarian;

  /// Diet option: vegan dishes.
  ///
  /// In de, this message translates to:
  /// **'Vegane Gerichte'**
  String get businessVegan;

  /// Label of the doctor specialty choice.
  ///
  /// In de, this message translates to:
  /// **'Fachrichtung'**
  String get businessSpecialtyLabel;

  /// Label of the accepted insurance choice.
  ///
  /// In de, this message translates to:
  /// **'Versicherung'**
  String get businessInsuranceLabel;

  /// Accepted insurance: statutory.
  ///
  /// In de, this message translates to:
  /// **'Gesetzlich'**
  String get insuranceStatutory;

  /// Accepted insurance: private.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get insurancePrivate;

  /// Accepted insurance: both.
  ///
  /// In de, this message translates to:
  /// **'Gesetzlich und privat'**
  String get insuranceBoth;

  /// Snackbar after saving an owner editor.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert.'**
  String get businessSaved;

  /// Description validation error.
  ///
  /// In de, this message translates to:
  /// **'Die Beschreibung muss 20 bis 3000 Zeichen lang sein.'**
  String get businessDescriptionInvalid;

  /// Phone validation error.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine Telefonnummer mit 5 bis 40 Zeichen an.'**
  String get businessPhoneInvalid;

  /// Website validation error.
  ///
  /// In de, this message translates to:
  /// **'Die Website muss mit https:// beginnen.'**
  String get businessWebsiteInvalid;

  /// Languages validation error.
  ///
  /// In de, this message translates to:
  /// **'Wähle mindestens eine Sprache.'**
  String get businessLanguagesRequired;

  /// Cuisines validation error.
  ///
  /// In de, this message translates to:
  /// **'Wähle mindestens eine Küche.'**
  String get businessCuisinesRequired;

  /// Price level validation error.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Preisniveau.'**
  String get businessPriceRequired;

  /// Specialty validation error.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Fachrichtung.'**
  String get businessSpecialtyRequired;

  /// Insurance validation error.
  ///
  /// In de, this message translates to:
  /// **'Wähle, welche Versicherung du annimmst.'**
  String get businessInsuranceRequired;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Kurdisch'**
  String get cuisineKurdish;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Syrisch'**
  String get cuisineSyrian;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Türkisch'**
  String get cuisineTurkish;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Arabisch'**
  String get cuisineArabic;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Persisch'**
  String get cuisinePersian;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Libanesisch'**
  String get cuisineLebanese;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Irakisch'**
  String get cuisineIraqi;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Orientalisch'**
  String get cuisineMiddleEastern;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Kebab & Döner'**
  String get cuisineKebab;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Falafel'**
  String get cuisineFalafel;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get cuisineGerman;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Italienisch'**
  String get cuisineItalian;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Mediterran'**
  String get cuisineMediterranean;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Indisch'**
  String get cuisineIndian;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'Asiatisch'**
  String get cuisineAsian;

  /// Directory cuisine label.
  ///
  /// In de, this message translates to:
  /// **'International'**
  String get cuisineInternational;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Allgemeinmedizin'**
  String get specialtyGeneralMedicine;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Innere Medizin'**
  String get specialtyInternalMedicine;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Kinderheilkunde'**
  String get specialtyPediatrics;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Frauenheilkunde'**
  String get specialtyGynecology;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Hautheilkunde'**
  String get specialtyDermatology;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Orthopädie'**
  String get specialtyOrthopedics;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Neurologie'**
  String get specialtyNeurology;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Psychiatrie'**
  String get specialtyPsychiatry;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Augenheilkunde'**
  String get specialtyOphthalmology;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'HNO'**
  String get specialtyEnt;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Zahnmedizin'**
  String get specialtyDentistry;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Kardiologie'**
  String get specialtyCardiology;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Urologie'**
  String get specialtyUrology;

  /// Doctor specialty label.
  ///
  /// In de, this message translates to:
  /// **'Andere'**
  String get specialtyOther;

  /// Weekday without opening intervals.
  ///
  /// In de, this message translates to:
  /// **'Geschlossen'**
  String get businessHoursClosed;

  /// Adds an opening interval to a weekday.
  ///
  /// In de, this message translates to:
  /// **'Zeitfenster hinzufügen'**
  String get businessHoursAdd;

  /// An opening interval.
  ///
  /// In de, this message translates to:
  /// **'{opens} – {closes}'**
  String businessHoursInterval({required String opens, required String closes});

  /// An opening interval that ends after midnight.
  ///
  /// In de, this message translates to:
  /// **'{opens} – {closes} (nächster Tag)'**
  String businessHoursOvernight({
    required String opens,
    required String closes,
  });

  /// Time picker title for the opening time.
  ///
  /// In de, this message translates to:
  /// **'Öffnet um'**
  String get businessHoursPickOpen;

  /// Time picker title for the closing time.
  ///
  /// In de, this message translates to:
  /// **'Schließt um'**
  String get businessHoursPickClose;

  /// Explains overnight intervals.
  ///
  /// In de, this message translates to:
  /// **'Schließt ihr nach Mitternacht, wähle einfach die Uhrzeit am nächsten Morgen.'**
  String get businessHoursHint;

  /// Validation error for an empty interval.
  ///
  /// In de, this message translates to:
  /// **'Öffnungs- und Schließzeit dürfen nicht gleich sein.'**
  String get businessHoursSameTime;

  /// Validation error for too many intervals.
  ///
  /// In de, this message translates to:
  /// **'Höchstens 6 Zeitfenster pro Tag.'**
  String get businessHoursTooMany;

  /// Semantic label of the remove-interval button.
  ///
  /// In de, this message translates to:
  /// **'Zeitfenster entfernen'**
  String get businessHoursRemove;

  /// Weekday name.
  ///
  /// In de, this message translates to:
  /// **'Montag'**
  String get weekdayMonday;

  /// Weekday name.
  ///
  /// In de, this message translates to:
  /// **'Dienstag'**
  String get weekdayTuesday;

  /// Weekday name.
  ///
  /// In de, this message translates to:
  /// **'Mittwoch'**
  String get weekdayWednesday;

  /// Weekday name.
  ///
  /// In de, this message translates to:
  /// **'Donnerstag'**
  String get weekdayThursday;

  /// Weekday name.
  ///
  /// In de, this message translates to:
  /// **'Freitag'**
  String get weekdayFriday;

  /// Weekday name.
  ///
  /// In de, this message translates to:
  /// **'Samstag'**
  String get weekdaySaturday;

  /// Weekday name.
  ///
  /// In de, this message translates to:
  /// **'Sonntag'**
  String get weekdaySunday;

  /// Empty state of the menu editor.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bereiche. Lege zum Beispiel „Vorspeisen“ oder „Getränke“ an.'**
  String get businessMenuEmpty;

  /// Adds a menu section.
  ///
  /// In de, this message translates to:
  /// **'Bereich hinzufügen'**
  String get businessMenuAddSection;

  /// Menu section name field.
  ///
  /// In de, this message translates to:
  /// **'Name des Bereichs'**
  String get businessMenuSectionName;

  /// Adds a dish to a section.
  ///
  /// In de, this message translates to:
  /// **'Gericht hinzufügen'**
  String get businessMenuAddItem;

  /// Title of the dish form.
  ///
  /// In de, this message translates to:
  /// **'Gericht bearbeiten'**
  String get businessMenuEditItem;

  /// Dish name field.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get businessMenuItemName;

  /// Dish description field.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung (optional)'**
  String get businessMenuItemDescription;

  /// Dish price field.
  ///
  /// In de, this message translates to:
  /// **'Preis in €'**
  String get businessMenuItemPrice;

  /// Dish availability switch.
  ///
  /// In de, this message translates to:
  /// **'Verfügbar'**
  String get businessMenuItemAvailable;

  /// Badge of an unavailable dish.
  ///
  /// In de, this message translates to:
  /// **'Nicht verfügbar'**
  String get businessMenuItemUnavailable;

  /// Reorder action.
  ///
  /// In de, this message translates to:
  /// **'Nach oben'**
  String get businessMenuMoveUp;

  /// Reorder action.
  ///
  /// In de, this message translates to:
  /// **'Nach unten'**
  String get businessMenuMoveDown;

  /// Dish price validation error.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen gültigen Preis an.'**
  String get businessMenuPriceInvalid;

  /// Name validation error.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen an.'**
  String get businessMenuNameRequired;

  /// Confirmation before deleting a menu section.
  ///
  /// In de, this message translates to:
  /// **'Bereich „{name}“ mit allen Gerichten löschen?'**
  String businessMenuDeleteSection({required String name});

  /// Dish flag.
  ///
  /// In de, this message translates to:
  /// **'Vegetarisch'**
  String get menuFlagVegetarian;

  /// Dish flag.
  ///
  /// In de, this message translates to:
  /// **'Vegan'**
  String get menuFlagVegan;
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
