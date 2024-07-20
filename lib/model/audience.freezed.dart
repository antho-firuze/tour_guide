// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audience.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Audience _$AudienceFromJson(Map<String, dynamic> json) {
  return _Audience.fromJson(json);
}

/// @nodoc
mixin _$Audience {
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'presenter_id')
  int? get presenterId => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_id')
  String get deviceId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get answer => throw _privateConstructorUsedError;
  DateTime? get heartbeat => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AudienceCopyWith<Audience> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudienceCopyWith<$Res> {
  factory $AudienceCopyWith(Audience value, $Res Function(Audience) then) =
      _$AudienceCopyWithImpl<$Res, Audience>;
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'presenter_id') int? presenterId,
      @JsonKey(name: 'device_id') String deviceId,
      Map<String, dynamic>? answer,
      DateTime? heartbeat,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$AudienceCopyWithImpl<$Res, $Val extends Audience>
    implements $AudienceCopyWith<$Res> {
  _$AudienceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? presenterId = freezed,
    Object? deviceId = null,
    Object? answer = freezed,
    Object? heartbeat = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      presenterId: freezed == presenterId
          ? _value.presenterId
          : presenterId // ignore: cast_nullable_to_non_nullable
              as int?,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      answer: freezed == answer
          ? _value.answer
          : answer // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      heartbeat: freezed == heartbeat
          ? _value.heartbeat
          : heartbeat // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AudienceImplCopyWith<$Res>
    implements $AudienceCopyWith<$Res> {
  factory _$$AudienceImplCopyWith(
          _$AudienceImpl value, $Res Function(_$AudienceImpl) then) =
      __$$AudienceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'presenter_id') int? presenterId,
      @JsonKey(name: 'device_id') String deviceId,
      Map<String, dynamic>? answer,
      DateTime? heartbeat,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$AudienceImplCopyWithImpl<$Res>
    extends _$AudienceCopyWithImpl<$Res, _$AudienceImpl>
    implements _$$AudienceImplCopyWith<$Res> {
  __$$AudienceImplCopyWithImpl(
      _$AudienceImpl _value, $Res Function(_$AudienceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? presenterId = freezed,
    Object? deviceId = null,
    Object? answer = freezed,
    Object? heartbeat = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$AudienceImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      presenterId: freezed == presenterId
          ? _value.presenterId
          : presenterId // ignore: cast_nullable_to_non_nullable
              as int?,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      answer: freezed == answer
          ? _value._answer
          : answer // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      heartbeat: freezed == heartbeat
          ? _value.heartbeat
          : heartbeat // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AudienceImpl implements _Audience {
  _$AudienceImpl(
      {this.id,
      @JsonKey(name: 'presenter_id') this.presenterId,
      @JsonKey(name: 'device_id') this.deviceId = '',
      final Map<String, dynamic>? answer,
      this.heartbeat,
      @JsonKey(name: 'created_at') this.createdAt})
      : _answer = answer;

  factory _$AudienceImpl.fromJson(Map<String, dynamic> json) =>
      _$$AudienceImplFromJson(json);

  @override
  final int? id;
  @override
  @JsonKey(name: 'presenter_id')
  final int? presenterId;
  @override
  @JsonKey(name: 'device_id')
  final String deviceId;
  final Map<String, dynamic>? _answer;
  @override
  Map<String, dynamic>? get answer {
    final value = _answer;
    if (value == null) return null;
    if (_answer is EqualUnmodifiableMapView) return _answer;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? heartbeat;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Audience(id: $id, presenterId: $presenterId, deviceId: $deviceId, answer: $answer, heartbeat: $heartbeat, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudienceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.presenterId, presenterId) ||
                other.presenterId == presenterId) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            const DeepCollectionEquality().equals(other._answer, _answer) &&
            (identical(other.heartbeat, heartbeat) ||
                other.heartbeat == heartbeat) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, presenterId, deviceId,
      const DeepCollectionEquality().hash(_answer), heartbeat, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AudienceImplCopyWith<_$AudienceImpl> get copyWith =>
      __$$AudienceImplCopyWithImpl<_$AudienceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AudienceImplToJson(
      this,
    );
  }
}

abstract class _Audience implements Audience {
  factory _Audience(
      {final int? id,
      @JsonKey(name: 'presenter_id') final int? presenterId,
      @JsonKey(name: 'device_id') final String deviceId,
      final Map<String, dynamic>? answer,
      final DateTime? heartbeat,
      @JsonKey(name: 'created_at') final DateTime? createdAt}) = _$AudienceImpl;

  factory _Audience.fromJson(Map<String, dynamic> json) =
      _$AudienceImpl.fromJson;

  @override
  int? get id;
  @override
  @JsonKey(name: 'presenter_id')
  int? get presenterId;
  @override
  @JsonKey(name: 'device_id')
  String get deviceId;
  @override
  Map<String, dynamic>? get answer;
  @override
  DateTime? get heartbeat;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$AudienceImplCopyWith<_$AudienceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
