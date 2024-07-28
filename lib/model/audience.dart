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
    @Default('join') String state,
  }) = _Audience;

  factory Audience.fromJson(Map<String, dynamic> json) => _$AudienceFromJson(json);
}
