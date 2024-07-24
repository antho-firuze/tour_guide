import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/signaling/signaling2_controller.dart';
import 'package:tour_guide/utils/snackbar_service.dart';

class AudienceCtrl {
  Ref ref;
  AudienceCtrl(this.ref);

  Future join(Presenter presenter) async {
    ref.read(signaling2CtrlProvider).connectionTimeout = ref.read(timeoutProvider);
    ref.read(signaling2CtrlProvider).onTimeout = () {
      SnackBarService.show(message: 'Connection timeout !');
    };
    ref.read(signaling2CtrlProvider).onDisconnected = () {
      SnackBarService.show(message: 'This session has been ended !');
    };
    ref.read(signaling2CtrlProvider).onFailed = () {
      SnackBarService.show(message: 'The connection could not be establised !');
    };

    await ref.read(signaling2CtrlProvider).join(presenter);
  }

  Future stop() async {
    await ref.read(signaling2CtrlProvider).close(ref.read(audienceProvider)!.id!);
  }
}

final audienceCtrlProvider = Provider(AudienceCtrl.new);
