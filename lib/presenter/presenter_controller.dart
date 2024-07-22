import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/presenter/presenter_service.dart';
import 'package:tour_guide/signaling/signaling_controller.dart';
import 'package:tour_guide/signaling/signaling_service.dart';
import 'package:tour_guide/utils/datetime_utils.dart';

final presenterProvider = StateProvider<Presenter?>((ref) => null);

class PresenterCtrl {
  Ref ref;
  PresenterCtrl(this.ref);

  Future start() async {
    try {
      await ref.read(signalingServiceProvider).removeCandidate(CandidateType.presenter, ref.read(deviceIdProvider));
      await ref.read(presenterSvcProvider).remove(ref.read(deviceIdProvider));

      final data = {
        "label": "Muharram",
        "device_id": ref.read(deviceIdProvider),
        "heartbeat": DateTime.now().dbDateTime(),
      };
      final state = await AsyncValue.guard(() async => await ref.read(presenterSvcProvider).upsert(data));

      final presenter = Presenter.fromJson(state.value);

      await ref.read(signalingCtrlProvider).create(presenter);

      ref.read(presenterProvider.notifier).state = presenter;
    } catch (e) {
      log('PresenterCtrl | start', error: e, name: 'signaling');
    }
  }

  Future stop() async {
    if (await ref.read(signalingCtrlProvider).close()) {
      await ref.read(presenterSvcProvider).remove(ref.read(deviceIdProvider));
      ref.read(presenterProvider.notifier).state = null;
    }
  }
}

final presenterCtrlProvider = Provider(PresenterCtrl.new);
