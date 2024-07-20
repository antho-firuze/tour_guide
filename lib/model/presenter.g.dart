// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presenter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PresenterImpl _$$PresenterImplFromJson(Map<String, dynamic> json) =>
    _$PresenterImpl(
      id: (json['id'] as num?)?.toInt(),
      deviceId: json['device_id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      offer: json['offer'] as Map<String, dynamic>?,
      heartbeat: json['heartbeat'] == null
          ? null
          : DateTime.parse(json['heartbeat'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$PresenterImplToJson(_$PresenterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_id': instance.deviceId,
      'label': instance.label,
      'offer': instance.offer,
      'heartbeat': instance.heartbeat?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };
