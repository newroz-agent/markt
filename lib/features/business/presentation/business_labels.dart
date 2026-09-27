import 'package:flutter/material.dart';

import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_repository.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

extension DirectoryTypeLabel on DirectoryType {
  String label(AppLocalizations l10n) => switch (this) {
    DirectoryType.restaurant => l10n.directoryTypeRestaurant,
    DirectoryType.cafe => l10n.directoryTypeCafe,
    DirectoryType.fastFood => l10n.directoryTypeFastFood,
    DirectoryType.doctor => l10n.directoryTypeDoctor,
  };

  IconData get icon => switch (this) {
    DirectoryType.restaurant => Icons.restaurant_outlined,
    DirectoryType.cafe => Icons.local_cafe_outlined,
    DirectoryType.fastFood => Icons.lunch_dining_outlined,
    DirectoryType.doctor => Icons.medical_services_outlined,
  };
}

extension DirectoryCuisineLabel on DirectoryCuisine {
  String label(AppLocalizations l10n) => switch (this) {
    DirectoryCuisine.kurdish => l10n.cuisineKurdish,
    DirectoryCuisine.syrian => l10n.cuisineSyrian,
    DirectoryCuisine.turkish => l10n.cuisineTurkish,
    DirectoryCuisine.arabic => l10n.cuisineArabic,
    DirectoryCuisine.persian => l10n.cuisinePersian,
    DirectoryCuisine.lebanese => l10n.cuisineLebanese,
    DirectoryCuisine.iraqi => l10n.cuisineIraqi,
    DirectoryCuisine.middleEastern => l10n.cuisineMiddleEastern,
    DirectoryCuisine.kebab => l10n.cuisineKebab,
    DirectoryCuisine.falafel => l10n.cuisineFalafel,
    DirectoryCuisine.german => l10n.cuisineGerman,
    DirectoryCuisine.italian => l10n.cuisineItalian,
    DirectoryCuisine.mediterranean => l10n.cuisineMediterranean,
    DirectoryCuisine.indian => l10n.cuisineIndian,
    DirectoryCuisine.asian => l10n.cuisineAsian,
    DirectoryCuisine.international => l10n.cuisineInternational,
  };
}

extension SpokenLanguageLabel on SpokenLanguage {
  String label(AppLocalizations l10n) => switch (this) {
    SpokenLanguage.kurdish => l10n.languageKurdish,
    SpokenLanguage.arabic => l10n.languageArabic,
    SpokenLanguage.turkish => l10n.languageTurkish,
    SpokenLanguage.german => l10n.languageGerman,
    SpokenLanguage.english => l10n.languageEnglish,
  };
}

extension DoctorSpecialtyLabel on DoctorSpecialty {
  String label(AppLocalizations l10n) => switch (this) {
    DoctorSpecialty.generalMedicine => l10n.specialtyGeneralMedicine,
    DoctorSpecialty.internalMedicine => l10n.specialtyInternalMedicine,
    DoctorSpecialty.pediatrics => l10n.specialtyPediatrics,
    DoctorSpecialty.gynecology => l10n.specialtyGynecology,
    DoctorSpecialty.dermatology => l10n.specialtyDermatology,
    DoctorSpecialty.orthopedics => l10n.specialtyOrthopedics,
    DoctorSpecialty.neurology => l10n.specialtyNeurology,
    DoctorSpecialty.psychiatry => l10n.specialtyPsychiatry,
    DoctorSpecialty.ophthalmology => l10n.specialtyOphthalmology,
    DoctorSpecialty.ent => l10n.specialtyEnt,
    DoctorSpecialty.dentistry => l10n.specialtyDentistry,
    DoctorSpecialty.cardiology => l10n.specialtyCardiology,
    DoctorSpecialty.urology => l10n.specialtyUrology,
    DoctorSpecialty.other => l10n.specialtyOther,
  };
}

extension InsuranceAcceptanceLabel on InsuranceAcceptance {
  String label(AppLocalizations l10n) => switch (this) {
    InsuranceAcceptance.statutory => l10n.insuranceStatutory,
    InsuranceAcceptance.privateOnly => l10n.insurancePrivate,
    InsuranceAcceptance.both => l10n.insuranceBoth,
  };
}

extension SellerDocumentKindLabel on SellerDocumentKind {
  String label(AppLocalizations l10n) => switch (this) {
    SellerDocumentKind.identity => l10n.documentKindIdentity,
    SellerDocumentKind.businessRegistration =>
      l10n.documentKindBusinessRegistration,
    SellerDocumentKind.medicalProfessionalRegistration =>
      l10n.moderationDocumentKindMedicalProfessionalRegistration,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    SellerDocumentKind.identity => l10n.documentKindIdentityHint,
    SellerDocumentKind.businessRegistration =>
      l10n.documentKindBusinessRegistrationHint,
    SellerDocumentKind.medicalProfessionalRegistration =>
      l10n.documentKindMedicalHint,
  };

  IconData get icon => switch (this) {
    SellerDocumentKind.identity => Icons.badge_outlined,
    SellerDocumentKind.businessRegistration => Icons.store_outlined,
    SellerDocumentKind.medicalProfessionalRegistration =>
      Icons.medical_information_outlined,
  };
}

/// Database weekdays in display order: Monday first, Sunday last.
const displayWeekdays = <int>[1, 2, 3, 4, 5, 6, 0];

String weekdayLabel(AppLocalizations l10n, int weekday) => switch (weekday) {
  1 => l10n.weekdayMonday,
  2 => l10n.weekdayTuesday,
  3 => l10n.weekdayWednesday,
  4 => l10n.weekdayThursday,
  5 => l10n.weekdayFriday,
  6 => l10n.weekdaySaturday,
  _ => l10n.weekdaySunday,
};

String formatDirectoryTime(BuildContext context, DirectoryTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour % 24, minute: time.minute),
      alwaysUse24HourFormat: true,
    );

String businessFailureMessage(AppLocalizations l10n, Object error) {
  if (error is! BusinessException) return l10n.stateErrorMessage;
  return switch (error.reason) {
    BusinessFailureReason.privateSeller => l10n.businessPrivateSellerBody,
    BusinessFailureReason.invalidBusinessName => l10n.businessErrorName,
    BusinessFailureReason.unsupportedCity => l10n.businessErrorCity,
    BusinessFailureReason.typeLockedByProfile => l10n.businessTypeLockedHint,
    BusinessFailureReason.documentAlreadyPending =>
      l10n.businessErrorDocumentPending,
    BusinessFailureReason.fileTooLarge => l10n.businessErrorFileTooLarge,
    BusinessFailureReason.invalidInput => l10n.businessErrorInvalid,
    _ => l10n.stateErrorMessage,
  };
}
