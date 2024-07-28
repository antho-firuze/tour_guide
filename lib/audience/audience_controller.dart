import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/signaling/signaling_controller.dart';
import 'package:tour_guide/utils/snackbar_service.dart';

class AudienceCtrl {
  Ref ref;
  AudienceCtrl(this.ref);

  Future joinMeeting(Presenter presenter) async {
    try {
      log('joinMeeting', name: 'audience');

      ref.read(signalingCtrlProvider).connectionTimeout = ref.read(timeoutProvider);
      ref.read(signalingCtrlProvider).onTimeout = () {
        SnackBarService.show(message: 'Connection timeout !');
      };
      ref.read(signalingCtrlProvider).onDisconnected = () {
        SnackBarService.show(message: 'This session has been ended !');
      };
      ref.read(signalingCtrlProvider).onFailed = () {
        SnackBarService.show(message: 'The connection could not be establised !');
      };

      await ref.read(signalingCtrlProvider).joinMeeting(presenter);
    } catch (e) {
      log('joinMeeting | error', error: e, name: 'audience');
    }
  }

  Future leaveMeeting() async {
    try {
      log('leaveMeeting', name: 'audience');

      await ref.read(signalingCtrlProvider).leaveMeeting(ref.read(audienceProvider)!.id!);
    } catch (e) {
      log('leaveMeeting | error', error: e, name: 'audience');
    }
  }
}

final audienceCtrlProvider = Provider(AudienceCtrl.new);
