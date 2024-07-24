// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presenter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PresenterImpl _$$PresenterImplFromJson(Map<String, dynamic> json) =>
    _$PresenterImpl(
      id: (json['id'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      label: json['label'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      heartbeat: json['heartbeat'] == null
          ? null
          : DateTime.parse(json['heartbeat'] as String),
    );

Map<String, dynamic> _$$PresenterImplToJson(_$PresenterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt?.toIso8601String(),
      'label': instance.label,
      'device_id': instance.deviceId,
      'heartbeat': instance.heartbeat?.toIso8601String(),
    };
