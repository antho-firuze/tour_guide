// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audience.freezed.dart';
part 'audience.g.dart';

@freezed
class Audience with _$Audience {

  factory Audience({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'presenter_id') int? presenterId,
    @JsonKey(name: 'device_id') @Default('') String deviceId,
    Map<String, dynamic>? offer,
    @JsonKey(name: 'offer_candidate') List<Map<String, dynamic>>? offerCandidate,
    Map<String, dynamic>? answer,
    @JsonKey(name: 'answer_candidate') List<Map<String, dynamic>>? answerCandidate,
  }) = _Audience;

  factory Audience.fromJson(Map<String, dynamic> json) => _$AudienceFromJson(json);
}


@freezed
class AudienceState with _$AudienceState {

  factory AudienceState({
    int? id,
    @JsonKey(name: 'audience_id') int? audienceId,
    DateTime? heartbeat,
    @JsonKey(name: 'is_closed') @Default(false) bool isClosed,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _AudienceState;

  factory AudienceState.fromJson(Map<String, dynamic> json) => _$AudienceStateFromJson(json);
}