import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/signaling/signaling_controller.dart';

class PresenterCtrl {
  Ref ref;
  PresenterCtrl(this.ref);

  Future startMeeting() async {
    try {
      log('startMeeting', name: 'presenter');
      final data = {
        "label": ref.read(titleProvider),
        "device_id": ref.read(deviceIdProvider),
      };

      await ref.read(signalingCtrlProvider).startMeeting(data);
    } catch (e) {
      log('startMeeting | error', error: e, name: 'presenter');
    }
  }

  Future closeMeeting() async {
    try {
      log('closeMeeting', name: 'presenter');
      await ref.read(signalingCtrlProvider).closeMeeting(ref.read(presenterProvider)!.id!);
    } catch (e) {
      log('closeMeeting | error', error: e, name: 'presenter');
    }
  }
}

final presenterCtrlProvider = Provider(PresenterCtrl.new);
