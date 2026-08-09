// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'privacy_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PrivacySettings {
  NotificationPreferences get notifications =>
      throw _privateConstructorUsedError;
  bool get analyticsConsent => throw _privateConstructorUsedError;
  DateTime? get analyticsConsentAt => throw _privateConstructorUsedError;

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrivacySettingsCopyWith<PrivacySettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrivacySettingsCopyWith<$Res> {
  factory $PrivacySettingsCopyWith(
    PrivacySettings value,
    $Res Function(PrivacySettings) then,
  ) = _$PrivacySettingsCopyWithImpl<$Res, PrivacySettings>;
  @useResult
  $Res call({
    NotificationPreferences notifications,
    bool analyticsConsent,
    DateTime? analyticsConsentAt,
  });

  $NotificationPreferencesCopyWith<$Res> get notifications;
}

/// @nodoc
class _$PrivacySettingsCopyWithImpl<$Res, $Val extends PrivacySettings>
    implements $PrivacySettingsCopyWith<$Res> {
  _$PrivacySettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notifications = null,
    Object? analyticsConsent = null,
    Object? analyticsConsentAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            notifications: null == notifications
                ? _value.notifications
                : notifications // ignore: cast_nullable_to_non_nullable
                      as NotificationPreferences,
            analyticsConsent: null == analyticsConsent
                ? _value.analyticsConsent
                : analyticsConsent // ignore: cast_nullable_to_non_nullable
                      as bool,
            analyticsConsentAt: freezed == analyticsConsentAt
                ? _value.analyticsConsentAt
                : analyticsConsentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationPreferencesCopyWith<$Res> get notifications {
    return $NotificationPreferencesCopyWith<$Res>(_value.notifications, (
      value,
    ) {
      return _then(_value.copyWith(notifications: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PrivacySettingsImplCopyWith<$Res>
    implements $PrivacySettingsCopyWith<$Res> {
  factory _$$PrivacySettingsImplCopyWith(
    _$PrivacySettingsImpl value,
    $Res Function(_$PrivacySettingsImpl) then,
  ) = __$$PrivacySettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    NotificationPreferences notifications,
    bool analyticsConsent,
    DateTime? analyticsConsentAt,
  });

  @override
  $NotificationPreferencesCopyWith<$Res> get notifications;
}

/// @nodoc
class __$$PrivacySettingsImplCopyWithImpl<$Res>
    extends _$PrivacySettingsCopyWithImpl<$Res, _$PrivacySettingsImpl>
    implements _$$PrivacySettingsImplCopyWith<$Res> {
  __$$PrivacySettingsImplCopyWithImpl(
    _$PrivacySettingsImpl _value,
    $Res Function(_$PrivacySettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notifications = null,
    Object? analyticsConsent = null,
    Object? analyticsConsentAt = freezed,
  }) {
    return _then(
      _$PrivacySettingsImpl(
        notifications: null == notifications
            ? _value.notifications
            : notifications // ignore: cast_nullable_to_non_nullable
                  as NotificationPreferences,
        analyticsConsent: null == analyticsConsent
            ? _value.analyticsConsent
            : analyticsConsent // ignore: cast_nullable_to_non_nullable
                  as bool,
        analyticsConsentAt: freezed == analyticsConsentAt
            ? _value.analyticsConsentAt
            : analyticsConsentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$PrivacySettingsImpl extends _PrivacySettings {
  const _$PrivacySettingsImpl({
    this.notifications = const NotificationPreferences(),
    this.analyticsConsent = false,
    this.analyticsConsentAt,
  }) : super._();

  @override
  @JsonKey()
  final NotificationPreferences notifications;
  @override
  @JsonKey()
  final bool analyticsConsent;
  @override
  final DateTime? analyticsConsentAt;

  @override
  String toString() {
    return 'PrivacySettings(notifications: $notifications, analyticsConsent: $analyticsConsent, analyticsConsentAt: $analyticsConsentAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrivacySettingsImpl &&
            (identical(other.notifications, notifications) ||
                other.notifications == notifications) &&
            (identical(other.analyticsConsent, analyticsConsent) ||
                other.analyticsConsent == analyticsConsent) &&
            (identical(other.analyticsConsentAt, analyticsConsentAt) ||
                other.analyticsConsentAt == analyticsConsentAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    notifications,
    analyticsConsent,
    analyticsConsentAt,
  );

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrivacySettingsImplCopyWith<_$PrivacySettingsImpl> get copyWith =>
      __$$PrivacySettingsImplCopyWithImpl<_$PrivacySettingsImpl>(
        this,
        _$identity,
      );
}

abstract class _PrivacySettings extends PrivacySettings {
  const factory _PrivacySettings({
    final NotificationPreferences notifications,
    final bool analyticsConsent,
    final DateTime? analyticsConsentAt,
  }) = _$PrivacySettingsImpl;
  const _PrivacySettings._() : super._();

  @override
  NotificationPreferences get notifications;
  @override
  bool get analyticsConsent;
  @override
  DateTime? get analyticsConsentAt;

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrivacySettingsImplCopyWith<_$PrivacySettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
