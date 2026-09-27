import 'package:flutter_test/flutter_test.dart';

import '../../tools/osm/osm_food.dart';

List<String>? _hours(String raw) =>
    parseOpeningHours(raw)?.map((interval) => interval.toString()).toList();

Map<String, dynamic> _node(Map<String, dynamic> tags) => {
  'type': 'node',
  'id': 42,
  'lat': 52.5,
  'lon': 13.4,
  'tags': tags,
};

void main() {
  group('cuisine filter', () {
    test('splits multi-value tags on ; with trim and lowercase', () {
      expect(cuisineValues(' Turkish ; kebab;;PIZZA '), [
        'turkish',
        'kebab',
        'pizza',
      ]);
      expect(mapCuisines('turkish;kebab'), ['turkish', 'kebab']);
    });

    test('matches when any value is in scope', () {
      expect(mapCuisines('pizza;kebab'), ['kebab']);
      expect(mapCuisines('burger;pizza'), isEmpty);
      expect(mapCuisines(null), isEmpty);
    });

    test('maps agreed aliases and deduplicates', () {
      expect(mapCuisines('arab;egyptian;yemeni'), ['arabic']);
      expect(mapCuisines('döner;shawarma'), ['kebab']);
      expect(mapCuisines('iranian'), ['persian']);
      expect(mapCuisines('oriental;levantine;palestinian'), ['middle_eastern']);
    });

    test('excludes afghan and unknown values', () {
      expect(mapCuisines('afghan'), isEmpty);
      expect(mapCuisines('syrianarabic'), isEmpty);
    });

    test('requires a name and an included amenity', () {
      expect(
        isInScope({'amenity': 'fast_food', 'name': 'A', 'cuisine': 'kebab'}),
        isTrue,
      );
      expect(
        isInScope({'amenity': 'fast_food', 'name': ' ', 'cuisine': 'kebab'}),
        isFalse,
      );
      expect(
        isInScope({'amenity': 'bar', 'name': 'A', 'cuisine': 'kebab'}),
        isFalse,
      );
    });
  });

  group('opening hours', () {
    test('parses weekday ranges into database weekdays (0 = Sunday)', () {
      expect(_hours('Mo-Fr 11:00-22:00'), [
        '1 11:00-22:00',
        '2 11:00-22:00',
        '3 11:00-22:00',
        '4 11:00-22:00',
        '5 11:00-22:00',
      ]);
      expect(_hours('Su 9:00-12:00'), ['0 09:00-12:00']);
    });

    test('applies later ; rules as overrides and , rules as additions', () {
      expect(_hours('Mo-Su 10:00-20:00; Su off'), [
        '1 10:00-20:00',
        '2 10:00-20:00',
        '3 10:00-20:00',
        '4 10:00-20:00',
        '5 10:00-20:00',
        '6 10:00-20:00',
      ]);
      expect(_hours('Sa 10:00-14:00, Su 12:00-14:00'), [
        '0 12:00-14:00',
        '6 10:00-14:00',
      ]);
      expect(_hours('Mo 10:00-12:00,14:00-18:00'), [
        '1 10:00-12:00',
        '1 14:00-18:00',
      ]);
    });

    test('supports wrap-around days, overnight closing and 24/7', () {
      expect(_hours('Sa-Mo 18:00-02:00'), [
        '0 18:00-02:00',
        '1 18:00-02:00',
        '6 18:00-02:00',
      ]);
      expect(_hours('Fr 18:00-24:00'), ['5 18:00-24:00']);
      expect(_hours('24/7'), hasLength(7));
      expect(_hours('11:00-22:00'), hasLength(7));
      expect(_hours('Mo-Fr 10:00 - 18:00;'), hasLength(5));
    });

    test('rejects unsupported or ambiguous syntax', () {
      for (final raw in [
        'Mo-Su,PH 11:00-22:00',
        'Mo-Fr 10:00-18:00; PH off',
        'SH off',
        'Mo-Fr sunrise-sunset',
        'week 1-20 Mo 10:00-12:00',
        'Apr-Oct: 08:00-18:30',
        'Dec 24 off',
        'Mo-Fr 10:00-18:00 "by appointment"',
        'by appointment',
        'Mo-Su 11:00+',
        'Mo-Th 09:00-26:00',
        'Mo[1] 10:00-12:00',
        'Mo-Fr 10:00-18:00 || "call us"',
        'Mo-Su 10:00-10:00',
        'Mo-Su 08:00-00:00, Fr-Sa 08:00-01:00',
        'Mo off',
        'closed',
        'mo-fr 10:00-18:00',
        '',
      ]) {
        expect(parseOpeningHours(raw), isNull, reason: raw);
      }
    });
  });

  group('element mapping', () {
    test('maps only OSM-provided fields', () {
      final mapped = mapElement(
        _node({
          'amenity': 'fast_food',
          'name': ' Beispiel Imbiss ',
          'cuisine': 'turkish;kebab;pizza',
          'addr:street': 'Oranienstraße',
          'addr:housenumber': '1',
          'addr:postcode': '10999',
          'contact:phone': '+49 30 1234567; +49 30 7654321',
          'website': 'www.example.de',
          'contact:email': 'mailto:Info@Example.de',
          'diet:halal': 'only',
          'diet:vegan': 'no',
          'opening_hours': 'Mo-Su 11:00-23:00',
        }),
      )!;

      expect(mapped.payload, containsPair('name', 'Beispiel Imbiss'));
      expect(mapped.payload, containsPair('cuisines', ['turkish', 'kebab']));
      expect(
        mapped.payload,
        containsPair('osm_cuisine', 'turkish;kebab;pizza'),
      );
      expect(mapped.payload, containsPair('phone', '+49 30 1234567'));
      expect(mapped.payload, containsPair('website', 'https://www.example.de'));
      expect(mapped.payload, containsPair('email', 'info@example.de'));
      expect(mapped.payload, containsPair('has_halal', true));
      expect(mapped.payload, containsPair('has_vegan', null));
      expect(mapped.payload, containsPair('addr_city', null));
      expect(mapped.payload['hours'], hasLength(7));
      expect(mapped.rejectedHours, isNull);
      expect(mapped.payload.keys, isNot(contains('description')));
    });

    test('uses the center of ways and reports rejected hours', () {
      final mapped = mapElement({
        'type': 'way',
        'id': 7,
        'center': {'lat': 52.4, 'lon': 13.3},
        'tags': {
          'amenity': 'restaurant',
          'name': 'Beispiel',
          'cuisine': 'lebanese',
          'opening_hours': 'Mo-Su,PH 12:00-22:00',
          'website': 'HTTP://Example.de',
        },
      })!;

      expect(mapped.payload, containsPair('latitude', 52.4));
      expect(mapped.payload, containsPair('website', 'http://Example.de'));
      expect(mapped.payload['hours'], isEmpty);
      expect(mapped.rejectedHours, 'Mo-Su,PH 12:00-22:00');
    });

    test('skips out-of-scope elements and drops invalid emails', () {
      expect(
        mapElement(
          _node({'amenity': 'restaurant', 'name': 'A', 'cuisine': 'afghan'}),
        ),
        isNull,
      );
      final mapped = mapElement(
        _node({
          'amenity': 'cafe',
          'name': 'A',
          'cuisine': 'turkish',
          'email': 'not an email',
        }),
      )!;
      expect(mapped.payload, containsPair('email', null));
    });
  });
}
