// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationPreferencesImpl _$$NotificationPreferencesImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationPreferencesImpl(
  orders: json['orders'] as bool? ?? true,
  chat: json['chat'] as bool? ?? true,
  offers: json['offers'] as bool? ?? false,
  priceDrops: json['priceDrops'] as bool? ?? true,
  system: json['system'] as bool? ?? true,
);

Map<String, dynamic> _$$NotificationPreferencesImplToJson(
  _$NotificationPreferencesImpl instance,
) => <String, dynamic>{
  'orders': instance.orders,
  'chat': instance.chat,
  'offers': instance.offers,
  'priceDrops': instance.priceDrops,
  'system': instance.system,
};
