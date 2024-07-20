import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_guide/common/device_service.dart';

final deviceIdProvider = StateProvider<String>((ref) => '');

class CommonCtrl {
  Ref ref;
  CommonCtrl(this.ref);

  void initialize() async {
    final result = await ref.read(deviceServiceProvider).getDeviceInfo();
    ref.read(deviceIdProvider.notifier).state = result['id'];
  }
}

final commonCtrlProvider = Provider(CommonCtrl.new);
