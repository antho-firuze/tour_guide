import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/signaling/signaling_controller.dart';
import 'package:tour_guide/utils/datetime_utils.dart';

class PresenterCtrl {
  Ref ref;
  PresenterCtrl(this.ref);

  Future start() async {
    try {
      final data = {
        "label": ref.read(titleProvider),
        "device_id": ref.read(deviceIdProvider),
        "heartbeat": DateTime.now().dbDateTime(),
      };

      await ref.read(signalingCtrlProvider).start(data);
    } catch (e) {
      log('PresenterCtrl | start', error: e, name: 'presenter');
    }
  }

  Future stop() async {
    try {
      await ref.read(signalingCtrlProvider).closeAllPeerConnection(ref.read(presenterProvider)!.id!);
    } catch (e) {
      log('PresenterCtrl | stop', error: e, name: 'presenter');
    }
  }
}

final presenterCtrlProvider = Provider(PresenterCtrl.new);
