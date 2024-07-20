// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audience.freezed.dart';
part 'audience.g.dart';

@freezed
class Audience with _$Audience {

  factory Audience({
    int? id,
    @JsonKey(name: 'presenter_id') int? presenterId,
    @JsonKey(name: 'device_id') @Default('') String deviceId,
    Map<String, dynamic>? answer,
    DateTime? heartbeat,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Audience;

  factory Audience.fromJson(Map<String, dynamic> json) => _$AudienceFromJson(json);
}