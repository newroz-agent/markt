import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/features/privacy/domain/notification_preferences.dart';

/// The keys `prepare_profile_privacy_preferences` validates inside
/// `profiles.notification_preferences`, copied from the migration by hand.
///
/// A rename on either side is invisible to the analyzer and to the type system:
/// the write succeeds, the JSON lands, and the toggle silently stops
/// round-tripping. These tests are the only guard on that contract.
const _sqlValidatedKeys = <String>{
  'orders',
  'chat',
  'offers',
  'priceDrops',
  'system',
};

/// Every channel off, so a test can turn exactly one on.
///
/// Spelled out literally rather than folded through `withChannel`, which is
/// itself under test here. `offers` is omitted because it already defaults to
/// false and the project rejects redundant argument values.
const _allOff = NotificationPreferences(
  orders: false,
  chat: false,
  priceDrops: false,
  system: false,
);

void main() {
  group('NotificationPreferences ↔ SQL contract', () {
    test('toJson emits exactly the keys the trigger validates', () {
      final json = const NotificationPreferences().toJson();

      expect(
        json.keys.toSet(),
        _sqlValidatedKeys,
        reason:
            'Key drift from phase5_compliance_notifications. Update the '
            'migration and this set together, never just one.',
      );
    });

    test('a channel added in Dart without a migration key is caught', () {
      // The trigger silently ignores keys outside its array, so a new enum
      // value whose key never reached SQL would never be validated.
      expect(
        const NotificationPreferences().toJson().keys.length,
        NotificationChannel.values.length,
      );
    });

    test('every channel round-trips through JSON independently', () {
      // One channel on at a time catches a copy-paste swap between two keys,
      // which an all-true or all-false fixture cannot see.
      for (final channel in NotificationChannel.values) {
        final only = _allOff.withChannel(channel, enabled: true);

        final restored = NotificationPreferences.fromJson(only.toJson());

        expect(
          restored,
          only,
          reason: '${channel.name} did not survive a JSON round trip',
        );
        for (final other in NotificationChannel.values) {
          expect(
            restored.isEnabled(other),
            other == channel,
            reason:
                'enabling ${channel.name} came back as ${other.name}: '
                'withChannel and isEnabled disagree on the mapping',
          );
        }
      }
    });

    test('every channel also round-trips when switched off', () {
      // Defaults are mostly true, so the on-path above would pass even if a
      // field were hard-coded. Flipping each one off closes that gap.
      for (final channel in NotificationChannel.values) {
        final off = const NotificationPreferences().withChannel(
          channel,
          enabled: false,
        );

        final restored = NotificationPreferences.fromJson(off.toJson());

        expect(restored.isEnabled(channel), isFalse, reason: channel.name);
        expect(restored, off, reason: channel.name);
      }
    });

    test('absent keys fall back to defaults rather than throwing', () {
      // The column is free-form jsonb, so a row written before a channel
      // existed is normal and must not crash the screen.
      expect(
        NotificationPreferences.fromJson(const {}),
        const NotificationPreferences(),
      );
    });

    test('a partial object keeps its stored value and defaults the rest', () {
      final restored = NotificationPreferences.fromJson(const {
        'orders': false,
      });

      expect(restored.isEnabled(NotificationChannel.orders), isFalse);
      expect(restored.isEnabled(NotificationChannel.chat), isTrue);
      expect(restored.isEnabled(NotificationChannel.offers), isFalse);
    });

    test('defaults match the column defaults in the migration', () {
      // Opt-out channels default on; marketing-shaped `offers` defaults off,
      // which is the consent posture the DSGVO slice depends on.
      const prefs = NotificationPreferences();

      expect(prefs.isEnabled(NotificationChannel.offers), isFalse);
      expect(prefs.isEnabled(NotificationChannel.orders), isTrue);
      expect(prefs.isEnabled(NotificationChannel.chat), isTrue);
      expect(prefs.isEnabled(NotificationChannel.priceDrops), isTrue);
      expect(prefs.isEnabled(NotificationChannel.system), isTrue);
    });
  });
}
