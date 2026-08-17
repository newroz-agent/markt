import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/home/data/unconfigured_home_repository.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

void main() {
  group('AdCampaign', () {
    test('maps localized copy and falls back to German', () {
      final campaign = AdCampaign.fromJson(const <String, dynamic>{
        'id': 'campaign-id',
        'slug': 'technik',
        'title_i18n': <String, dynamic>{
          'de': 'Technik, die weiterdenkt',
          'en': 'Technology that thinks ahead',
        },
        'subtitle_i18n': <String, dynamic>{'de': 'Ausgewahlte Gerate'},
        'image_url': 'https://example.com/campaign.jpg',
        'sort_order': 10,
      });

      expect(campaign.titleForLanguage('en'), 'Technology that thinks ahead');
      expect(campaign.titleForLanguage('ku'), 'Technik, die weiterdenkt');
      expect(campaign.subtitleForLanguage('tr'), 'Ausgewahlte Gerate');
    });
  });

  group('HomeProduct', () {
    test('maps nested store, images, VAT, and discount data', () {
      final product = HomeProduct.fromJson(const <String, dynamic>{
        'id': 'product-id',
        'slug': 'nova-x',
        'title': 'Wireless Kopfhorer Nova X',
        'description': 'Kabelloser Kopfhorer',
        'condition': 'new',
        'price_cents': 12999,
        'compare_at_price_cents': 15999,
        'currency': 'EUR',
        'vat_rate': 19,
        'price_includes_vat': true,
        'free_shipping': true,
        'shipping_cost_cents': 0,
        'rating_average': 4.88,
        'rating_count': 184,
        'city': 'Hamburg',
        'published_at': '2026-08-16T18:00:00Z',
        'seller': <String, dynamic>{
          'id': 'store-id',
          'slug': 'nordlicht-technik',
          'shop_name': 'Nordlicht Technik',
          'bio': 'Durchdachte Technik',
          'avatar_url': 'https://example.com/avatar.jpg',
          'banner_url': 'https://example.com/banner.jpg',
          'city': 'Hamburg',
          'rating_average': 4.91,
          'rating_count': 428,
          'response_time_minutes': 18,
        },
        'images': <Map<String, dynamic>>[
          <String, dynamic>{
            'image_url': 'https://example.com/product.jpg',
            'sort_order': 0,
          },
          <String, dynamic>{'image_url': '', 'sort_order': 1},
        ],
      });

      expect(product.store?.shopName, 'Nordlicht Technik');
      expect(product.imageUrls, <String>['https://example.com/product.jpg']);
      expect(product.priceIncludesVat, isTrue);
      expect(product.vatRate, 19);
      expect(product.isDiscounted, isTrue);
      expect(product.discountPercent, 19);
    });

    test('supports the default PostgREST relation name', () {
      final product = HomeProduct.fromJson(const <String, dynamic>{
        'id': 'product-id',
        'slug': 'product',
        'title': 'Product',
        'description': 'Description',
        'condition': 'used',
        'price_cents': 5000,
        'compare_at_price_cents': null,
        'currency': 'EUR',
        'published_at': '2026-08-16T18:00:00Z',
        'sellers': <String, dynamic>{
          'id': 'store-id',
          'slug': 'store',
          'shop_name': 'Store',
        },
      });

      expect(product.store?.shopName, 'Store');
      expect(product.isDiscounted, isFalse);
      expect(product.discountPercent, 0);
      expect(product.imageUrls, isEmpty);
    });
  });

  test('unconfigured repository exposes a typed backend error', () async {
    const repository = UnconfiguredHomeRepository();

    await expectLater(
      repository.fetchHomeFeed(),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppFailureCode.backendNotConfigured,
        ),
      ),
    );
  });
}
