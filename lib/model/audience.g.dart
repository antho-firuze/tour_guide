// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audience.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AudienceImpl _$$AudienceImplFromJson(Map<String, dynamic> json) =>
    _$AudienceImpl(
      id: (json['id'] as num?)?.toInt(),
      presenterId: (json['presenter_id'] as num?)?.toInt(),
      deviceId: json['device_id'] as String? ?? '',
      answer: json['answer'] as Map<String, dynamic>?,
      heartbeat: json['heartbeat'] == null
          ? null
          : DateTime.parse(json['heartbeat'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$AudienceImplToJson(_$AudienceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'presenter_id': instance.presenterId,
      'device_id': instance.deviceId,
      'answer': instance.answer,
      'heartbeat': instance.heartbeat?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };
