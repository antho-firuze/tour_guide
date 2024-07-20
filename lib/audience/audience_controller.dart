import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_guide/audience/audience_service.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/model/audience.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/signaling/signaling2_controller.dart';
import 'package:tour_guide/signaling/signaling_service.dart';
import 'package:tour_guide/utils/datetime_utils.dart';

final selectedPresenterProvider = StateProvider<Presenter?>((ref) => null);
final audienceProvider = StateProvider<Audience?>((ref) => null);

class AudienceCtrl {
  Ref ref;
  AudienceCtrl(this.ref);

  Future start(Presenter presenter) async {
    try {
      await ref.read(signalingServiceProvider).removeCandidate(CandidateType.audience, ref.read(deviceIdProvider));
      await ref.read(audienceSvcProvider).remove(ref.read(deviceIdProvider));

      final data = {
        "presenter_id": presenter.id,
        "device_id": ref.read(deviceIdProvider),
        "heartbeat": DateTime.now().dbDateTime(),
      };
      final state = await AsyncValue.guard(() async => await ref.read(audienceSvcProvider).upsert(data));

      final audience = Audience.fromJson(state.value);
      ref.read(audienceProvider.notifier).state = audience;

      ref.read(selectedPresenterProvider.notifier).state = presenter;

      await ref.read(signaling2CtrlProvider).openMedia();
      await ref.read(signaling2CtrlProvider).join();

      // log('result | ${state.value}', name: 'presenter');
    } catch (e) {
      // ref.read(errorProvider.notifier).state = e.toString();
      // log('createPeerConnection', error: e, name: 'signaling');
    }
  }

  Future stop() async {
    await ref.read(audienceSvcProvider).remove(ref.read(deviceIdProvider));
    await ref.read(signaling2CtrlProvider).close();
    ref.read(audienceProvider.notifier).state = null;
    ref.read(selectedPresenterProvider.notifier).state = null;
  }
}

final audienceCtrlProvider = Provider(AudienceCtrl.new);
