// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audience.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AudienceImpl _$$AudienceImplFromJson(Map<String, dynamic> json) =>
    _$AudienceImpl(
      id: (json['id'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      presenterId: (json['presenter_id'] as num?)?.toInt(),
      deviceId: json['device_id'] as String? ?? '',
      offer: json['offer'] as Map<String, dynamic>?,
      offerCandidate: (json['offer_candidate'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      answer: json['answer'] as Map<String, dynamic>?,
      answerCandidate: (json['answer_candidate'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$$AudienceImplToJson(_$AudienceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt?.toIso8601String(),
      'presenter_id': instance.presenterId,
      'device_id': instance.deviceId,
      'offer': instance.offer,
      'offer_candidate': instance.offerCandidate,
      'answer': instance.answer,
      'answer_candidate': instance.answerCandidate,
    };

_$AudienceStateImpl _$$AudienceStateImplFromJson(Map<String, dynamic> json) =>
    _$AudienceStateImpl(
      id: (json['id'] as num?)?.toInt(),
      audienceId: (json['audience_id'] as num?)?.toInt(),
      heartbeat: json['heartbeat'] == null
          ? null
          : DateTime.parse(json['heartbeat'] as String),
      isClosed: json['is_closed'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$AudienceStateImplToJson(_$AudienceStateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'audience_id': instance.audienceId,
      'heartbeat': instance.heartbeat?.toIso8601String(),
      'is_closed': instance.isClosed,
      'created_at': instance.createdAt?.toIso8601String(),
    };
