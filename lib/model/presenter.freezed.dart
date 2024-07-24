// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presenter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Presenter _$PresenterFromJson(Map<String, dynamic> json) {
  return _Presenter.fromJson(json);
}

/// @nodoc
mixin _$Presenter {
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_id')
  String get deviceId => throw _privateConstructorUsedError;
  DateTime? get heartbeat => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PresenterCopyWith<Presenter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PresenterCopyWith<$Res> {
  factory $PresenterCopyWith(Presenter value, $Res Function(Presenter) then) =
      _$PresenterCopyWithImpl<$Res, Presenter>;
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      String label,
      @JsonKey(name: 'device_id') String deviceId,
      DateTime? heartbeat});
}

/// @nodoc
class _$PresenterCopyWithImpl<$Res, $Val extends Presenter>
    implements $PresenterCopyWith<$Res> {
  _$PresenterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = freezed,
    Object? label = null,
    Object? deviceId = null,
    Object? heartbeat = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      heartbeat: freezed == heartbeat
          ? _value.heartbeat
          : heartbeat // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PresenterImplCopyWith<$Res>
    implements $PresenterCopyWith<$Res> {
  factory _$$PresenterImplCopyWith(
          _$PresenterImpl value, $Res Function(_$PresenterImpl) then) =
      __$$PresenterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      String label,
      @JsonKey(name: 'device_id') String deviceId,
      DateTime? heartbeat});
}

/// @nodoc
class __$$PresenterImplCopyWithImpl<$Res>
    extends _$PresenterCopyWithImpl<$Res, _$PresenterImpl>
    implements _$$PresenterImplCopyWith<$Res> {
  __$$PresenterImplCopyWithImpl(
      _$PresenterImpl _value, $Res Function(_$PresenterImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = freezed,
    Object? label = null,
    Object? deviceId = null,
    Object? heartbeat = freezed,
  }) {
    return _then(_$PresenterImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      heartbeat: freezed == heartbeat
          ? _value.heartbeat
          : heartbeat // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PresenterImpl implements _Presenter {
  _$PresenterImpl(
      {this.id,
      @JsonKey(name: 'created_at') this.createdAt,
      this.label = '',
      @JsonKey(name: 'device_id') this.deviceId = '',
      this.heartbeat});

  factory _$PresenterImpl.fromJson(Map<String, dynamic> json) =>
      _$$PresenterImplFromJson(json);

  @override
  final int? id;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey()
  final String label;
  @override
  @JsonKey(name: 'device_id')
  final String deviceId;
  @override
  final DateTime? heartbeat;

  @override
  String toString() {
    return 'Presenter(id: $id, createdAt: $createdAt, label: $label, deviceId: $deviceId, heartbeat: $heartbeat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PresenterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.heartbeat, heartbeat) ||
                other.heartbeat == heartbeat));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, createdAt, label, deviceId, heartbeat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PresenterImplCopyWith<_$PresenterImpl> get copyWith =>
      __$$PresenterImplCopyWithImpl<_$PresenterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PresenterImplToJson(
      this,
    );
  }
}

abstract class _Presenter implements Presenter {
  factory _Presenter(
      {final int? id,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      final String label,
      @JsonKey(name: 'device_id') final String deviceId,
      final DateTime? heartbeat}) = _$PresenterImpl;

  factory _Presenter.fromJson(Map<String, dynamic> json) =
      _$PresenterImpl.fromJson;

  @override
  int? get id;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  String get label;
  @override
  @JsonKey(name: 'device_id')
  String get deviceId;
  @override
  DateTime? get heartbeat;
  @override
  @JsonKey(ignore: true)
  _$$PresenterImplCopyWith<_$PresenterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
