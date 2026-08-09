// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'privacy_overview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PrivacyOverview {
  PrivacySettings get settings => throw _privateConstructorUsedError;
  List<DataSubjectRequest> get requests => throw _privateConstructorUsedError;

  /// Create a copy of PrivacyOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrivacyOverviewCopyWith<PrivacyOverview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrivacyOverviewCopyWith<$Res> {
  factory $PrivacyOverviewCopyWith(
    PrivacyOverview value,
    $Res Function(PrivacyOverview) then,
  ) = _$PrivacyOverviewCopyWithImpl<$Res, PrivacyOverview>;
  @useResult
  $Res call({PrivacySettings settings, List<DataSubjectRequest> requests});

  $PrivacySettingsCopyWith<$Res> get settings;
}

/// @nodoc
class _$PrivacyOverviewCopyWithImpl<$Res, $Val extends PrivacyOverview>
    implements $PrivacyOverviewCopyWith<$Res> {
  _$PrivacyOverviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrivacyOverview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? settings = null, Object? requests = null}) {
    return _then(
      _value.copyWith(
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as PrivacySettings,
            requests: null == requests
                ? _value.requests
                : requests // ignore: cast_nullable_to_non_nullable
                      as List<DataSubjectRequest>,
          )
          as $Val,
    );
  }

  /// Create a copy of PrivacyOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrivacySettingsCopyWith<$Res> get settings {
    return $PrivacySettingsCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PrivacyOverviewImplCopyWith<$Res>
    implements $PrivacyOverviewCopyWith<$Res> {
  factory _$$PrivacyOverviewImplCopyWith(
    _$PrivacyOverviewImpl value,
    $Res Function(_$PrivacyOverviewImpl) then,
  ) = __$$PrivacyOverviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PrivacySettings settings, List<DataSubjectRequest> requests});

  @override
  $PrivacySettingsCopyWith<$Res> get settings;
}

/// @nodoc
class __$$PrivacyOverviewImplCopyWithImpl<$Res>
    extends _$PrivacyOverviewCopyWithImpl<$Res, _$PrivacyOverviewImpl>
    implements _$$PrivacyOverviewImplCopyWith<$Res> {
  __$$PrivacyOverviewImplCopyWithImpl(
    _$PrivacyOverviewImpl _value,
    $Res Function(_$PrivacyOverviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrivacyOverview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? settings = null, Object? requests = null}) {
    return _then(
      _$PrivacyOverviewImpl(
        settings: null == settings
            ? _value.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as PrivacySettings,
        requests: null == requests
            ? _value._requests
            : requests // ignore: cast_nullable_to_non_nullable
                  as List<DataSubjectRequest>,
      ),
    );
  }
}

/// @nodoc

class _$PrivacyOverviewImpl extends _PrivacyOverview {
  const _$PrivacyOverviewImpl({
    this.settings = const PrivacySettings(),
    final List<DataSubjectRequest> requests = const <DataSubjectRequest>[],
  }) : _requests = requests,
       super._();

  @override
  @JsonKey()
  final PrivacySettings settings;
  final List<DataSubjectRequest> _requests;
  @override
  @JsonKey()
  List<DataSubjectRequest> get requests {
    if (_requests is EqualUnmodifiableListView) return _requests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requests);
  }

  @override
  String toString() {
    return 'PrivacyOverview(settings: $settings, requests: $requests)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrivacyOverviewImpl &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            const DeepCollectionEquality().equals(other._requests, _requests));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    settings,
    const DeepCollectionEquality().hash(_requests),
  );

  /// Create a copy of PrivacyOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrivacyOverviewImplCopyWith<_$PrivacyOverviewImpl> get copyWith =>
      __$$PrivacyOverviewImplCopyWithImpl<_$PrivacyOverviewImpl>(
        this,
        _$identity,
      );
}

abstract class _PrivacyOverview extends PrivacyOverview {
  const factory _PrivacyOverview({
    final PrivacySettings settings,
    final List<DataSubjectRequest> requests,
  }) = _$PrivacyOverviewImpl;
  const _PrivacyOverview._() : super._();

  @override
  PrivacySettings get settings;
  @override
  List<DataSubjectRequest> get requests;

  /// Create a copy of PrivacyOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrivacyOverviewImplCopyWith<_$PrivacyOverviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
