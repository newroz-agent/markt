// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NotificationPreferences _$NotificationPreferencesFromJson(
  Map<String, dynamic> json,
) {
  return _NotificationPreferences.fromJson(json);
}

/// @nodoc
mixin _$NotificationPreferences {
  bool get orders => throw _privateConstructorUsedError;
  bool get chat => throw _privateConstructorUsedError;
  bool get offers => throw _privateConstructorUsedError;
  bool get priceDrops => throw _privateConstructorUsedError;
  bool get system => throw _privateConstructorUsedError;

  /// Serializes this NotificationPreferences to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationPreferencesCopyWith<NotificationPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationPreferencesCopyWith<$Res> {
  factory $NotificationPreferencesCopyWith(
    NotificationPreferences value,
    $Res Function(NotificationPreferences) then,
  ) = _$NotificationPreferencesCopyWithImpl<$Res, NotificationPreferences>;
  @useResult
  $Res call({
    bool orders,
    bool chat,
    bool offers,
    bool priceDrops,
    bool system,
  });
}

/// @nodoc
class _$NotificationPreferencesCopyWithImpl<
  $Res,
  $Val extends NotificationPreferences
>
    implements $NotificationPreferencesCopyWith<$Res> {
  _$NotificationPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orders = null,
    Object? chat = null,
    Object? offers = null,
    Object? priceDrops = null,
    Object? system = null,
  }) {
    return _then(
      _value.copyWith(
            orders: null == orders
                ? _value.orders
                : orders // ignore: cast_nullable_to_non_nullable
                      as bool,
            chat: null == chat
                ? _value.chat
                : chat // ignore: cast_nullable_to_non_nullable
                      as bool,
            offers: null == offers
                ? _value.offers
                : offers // ignore: cast_nullable_to_non_nullable
                      as bool,
            priceDrops: null == priceDrops
                ? _value.priceDrops
                : priceDrops // ignore: cast_nullable_to_non_nullable
                      as bool,
            system: null == system
                ? _value.system
                : system // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationPreferencesImplCopyWith<$Res>
    implements $NotificationPreferencesCopyWith<$Res> {
  factory _$$NotificationPreferencesImplCopyWith(
    _$NotificationPreferencesImpl value,
    $Res Function(_$NotificationPreferencesImpl) then,
  ) = __$$NotificationPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool orders,
    bool chat,
    bool offers,
    bool priceDrops,
    bool system,
  });
}

/// @nodoc
class __$$NotificationPreferencesImplCopyWithImpl<$Res>
    extends
        _$NotificationPreferencesCopyWithImpl<
          $Res,
          _$NotificationPreferencesImpl
        >
    implements _$$NotificationPreferencesImplCopyWith<$Res> {
  __$$NotificationPreferencesImplCopyWithImpl(
    _$NotificationPreferencesImpl _value,
    $Res Function(_$NotificationPreferencesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orders = null,
    Object? chat = null,
    Object? offers = null,
    Object? priceDrops = null,
    Object? system = null,
  }) {
    return _then(
      _$NotificationPreferencesImpl(
        orders: null == orders
            ? _value.orders
            : orders // ignore: cast_nullable_to_non_nullable
                  as bool,
        chat: null == chat
            ? _value.chat
            : chat // ignore: cast_nullable_to_non_nullable
                  as bool,
        offers: null == offers
            ? _value.offers
            : offers // ignore: cast_nullable_to_non_nullable
                  as bool,
        priceDrops: null == priceDrops
            ? _value.priceDrops
            : priceDrops // ignore: cast_nullable_to_non_nullable
                  as bool,
        system: null == system
            ? _value.system
            : system // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationPreferencesImpl extends _NotificationPreferences {
  const _$NotificationPreferencesImpl({
    this.orders = true,
    this.chat = true,
    this.offers = false,
    this.priceDrops = true,
    this.system = true,
  }) : super._();

  factory _$NotificationPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationPreferencesImplFromJson(json);

  @override
  @JsonKey()
  final bool orders;
  @override
  @JsonKey()
  final bool chat;
  @override
  @JsonKey()
  final bool offers;
  @override
  @JsonKey()
  final bool priceDrops;
  @override
  @JsonKey()
  final bool system;

  @override
  String toString() {
    return 'NotificationPreferences(orders: $orders, chat: $chat, offers: $offers, priceDrops: $priceDrops, system: $system)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationPreferencesImpl &&
            (identical(other.orders, orders) || other.orders == orders) &&
            (identical(other.chat, chat) || other.chat == chat) &&
            (identical(other.offers, offers) || other.offers == offers) &&
            (identical(other.priceDrops, priceDrops) ||
                other.priceDrops == priceDrops) &&
            (identical(other.system, system) || other.system == system));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, orders, chat, offers, priceDrops, system);

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationPreferencesImplCopyWith<_$NotificationPreferencesImpl>
  get copyWith =>
      __$$NotificationPreferencesImplCopyWithImpl<
        _$NotificationPreferencesImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationPreferencesImplToJson(this);
  }
}

abstract class _NotificationPreferences extends NotificationPreferences {
  const factory _NotificationPreferences({
    final bool orders,
    final bool chat,
    final bool offers,
    final bool priceDrops,
    final bool system,
  }) = _$NotificationPreferencesImpl;
  const _NotificationPreferences._() : super._();

  factory _NotificationPreferences.fromJson(Map<String, dynamic> json) =
      _$NotificationPreferencesImpl.fromJson;

  @override
  bool get orders;
  @override
  bool get chat;
  @override
  bool get offers;
  @override
  bool get priceDrops;
  @override
  bool get system;

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationPreferencesImplCopyWith<_$NotificationPreferencesImpl>
  get copyWith => throw _privateConstructorUsedError;
}
