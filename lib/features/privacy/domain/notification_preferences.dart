import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';
part 'notification_preferences.g.dart';

/// The notification channels a user can opt out of.
///
/// The names are the literal keys of `profiles.notification_preferences`, so
/// the trigger `prepare_profile_privacy_preferences` validates exactly these
/// five and rejects a non-boolean value for any of them.
enum NotificationChannel { orders, chat, offers, priceDrops, system }

/// Per-channel opt-in state, defaulted to the same values as the column.
///
/// Missing keys fall back to those defaults rather than throwing: the column
/// is free-form `jsonb`, so a row written before a channel existed is normal.
@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @Default(true) bool orders,
    @Default(true) bool chat,
    @Default(false) bool offers,
    @Default(true) bool priceDrops,
    @Default(true) bool system,
  }) = _NotificationPreferences;

  const NotificationPreferences._();

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  bool isEnabled(NotificationChannel channel) => switch (channel) {
    NotificationChannel.orders => orders,
    NotificationChannel.chat => chat,
    NotificationChannel.offers => offers,
    NotificationChannel.priceDrops => priceDrops,
    NotificationChannel.system => system,
  };

  NotificationPreferences withChannel(
    NotificationChannel channel, {
    required bool enabled,
  }) => switch (channel) {
    NotificationChannel.orders => copyWith(orders: enabled),
    NotificationChannel.chat => copyWith(chat: enabled),
    NotificationChannel.offers => copyWith(offers: enabled),
    NotificationChannel.priceDrops => copyWith(priceDrops: enabled),
    NotificationChannel.system => copyWith(system: enabled),
  };
}
