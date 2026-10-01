import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';

void main() {
  test('maps database enum values, including snake_case ones', () {
    expect(DirectoryType.fromDatabase('fast_food'), DirectoryType.fastFood);
    expect(DirectoryType.fastFood.databaseValue, 'fast_food');
    expect(DirectoryCuisine.middleEastern.databaseValue, 'middle_eastern');
    expect(DoctorSpecialty.generalMedicine.databaseValue, 'general_medicine');
    expect(InsuranceAcceptance.privateOnly.databaseValue, 'private');
    expect(
      SellerDocumentKind.fromDatabase('medical_professional_registration'),
      SellerDocumentKind.medicalProfessionalRegistration,
    );
    expect(DirectoryType.fromDatabase('unknown'), isNull);
  });

  test('parses onboarding and picks the newest document per kind', () {
    final onboarding = DirectoryOnboarding.fromJson(<String, dynamic>{
      'seller': {
        'id': 's1',
        'kind': 'business',
        'status': 'pending',
        'shop_name': 'Praxis Dr. Test',
        'city': 'Berlin',
        'directory_type': 'doctor',
      },
      'is_verified': false,
      'required_document_kinds': [
        'identity',
        'medical_professional_registration',
      ],
      'documents': [
        {
          'id': 'new',
          'kind': 'medical_professional_registration',
          'status': 'pending',
          'admin_note': null,
          'mime_type': 'application/pdf',
          'storage_path': 's1/medical_professional_registration/2.pdf',
          'created_at': '2026-09-27T12:00:00Z',
        },
        {
          'id': 'old',
          'kind': 'medical_professional_registration',
          'status': 'rejected',
          'admin_note': 'Unleserlich',
          'mime_type': 'image/jpeg',
          'storage_path': 's1/medical_professional_registration/1.jpg',
          'created_at': '2026-09-26T12:00:00Z',
        },
        {
          'id': 'vat',
          'kind': 'vat_certificate',
          'status': 'approved',
          'admin_note': null,
          'mime_type': 'application/pdf',
          'storage_path': 's1/vat/1.pdf',
          'created_at': '2026-09-25T12:00:00Z',
        },
      ],
      'profile': null,
      'hours': [
        {'weekday': 5, 'opens_at': '22:00', 'closes_at': '02:00'},
      ],
      'menu': <Object>[],
    });

    expect(onboarding.directoryType, DirectoryType.doctor);
    expect(onboarding.requiredDocumentKinds, [
      SellerDocumentKind.identity,
      SellerDocumentKind.medicalProfessionalRegistration,
    ]);
    expect(
      onboarding
          .latestDocument(SellerDocumentKind.medicalProfessionalRegistration)
          ?.id,
      'new',
    );
    expect(onboarding.latestDocument(SellerDocumentKind.identity), isNull);
    expect(onboarding.documents.last.kind, isNull);
    expect(onboarding.approvedRequiredDocuments, 0);
    expect(onboarding.hours.single.isOvernight, isTrue);
  });

  test('profile RPC params clear the other type\'s fields', () {
    const doctor = DirectoryProfile(
      type: DirectoryType.doctor,
      description: 'Allgemeinmedizin für die ganze Familie.',
      phone: '030 1234567',
      languages: {SpokenLanguage.kurdish},
      cuisines: {DirectoryCuisine.kurdish},
      priceLevel: 2,
      hasHalal: true,
      specialty: DoctorSpecialty.pediatrics,
      insurance: InsuranceAcceptance.both,
    );
    final params = doctor.toRpcParams();
    expect(params['p_type'], 'doctor');
    expect(params['p_cuisines'], isEmpty);
    expect(params['p_price_level'], isNull);
    expect(params['p_has_halal'], isFalse);
    expect(params['p_specialty'], 'pediatrics');
    expect(params['p_insurance'], 'both');
    expect(params['p_languages'], ['kurdish']);
  });

  test('hours and menu serialize for the owner RPCs', () {
    final interval = OpeningInterval(
      weekday: 0,
      opensAt: DirectoryTime.parse('18:00'),
      closesAt: DirectoryTime.parse('24:00'),
    );
    expect(interval.toJson(3), {
      'weekday': 0,
      'opens_at': '18:00',
      'closes_at': '24:00',
      'sort_order': 3,
    });
    expect(interval.isOvernight, isFalse);

    const section = MenuSectionDraft(
      name: ' Vorspeisen ',
      items: [MenuItemDraft(name: 'Hummus', priceCents: 650, isVegan: true)],
    );
    final json = section.toJson(1);
    expect(json['name'], 'Vorspeisen');
    final item = (json['items'] as List).single as Map<String, dynamic>;
    expect(item['is_vegetarian'], isTrue, reason: 'vegan implies vegetarian');
    expect(item['price_cents'], 650);
    expect(item['sort_order'], 0);
  });
}
