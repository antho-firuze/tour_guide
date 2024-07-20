// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'presenter.freezed.dart';
part 'presenter.g.dart';

@freezed
class Presenter with _$Presenter {

  factory Presenter({
    int? id,
    @JsonKey(name: 'device_id') @Default('') String deviceId,
    @Default('') String label,
    Map<String, dynamic>? offer,
    DateTime? heartbeat,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Presenter;

  factory Presenter.fromJson(Map<String, dynamic> json) => _$PresenterFromJson(json);
}