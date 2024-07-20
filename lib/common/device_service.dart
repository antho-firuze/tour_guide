import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  Ref ref;
  DeviceService(this.ref);

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> result = {};

    try {
      if (kIsWeb) {
        var data = await deviceInfoPlugin.webBrowserInfo;
        result = {
          'id': const Uuid().v4(),
          'name': data.userAgent,
        };
        return result;
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            var data = await deviceInfoPlugin.androidInfo;
            result = {
              'id': '${data.device}:${data.id}',
              'name': '${data.manufacturer.toUpperCase()} ${data.model}',
            };
            return result;
          case TargetPlatform.iOS:
            var data = await deviceInfoPlugin.iosInfo;
            result = {
              'id': '${data.name}:${data.identifierForVendor}',
              'name': data.model,
            };
            return result;
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            result = {
              'id': const Uuid().v4(),
              'name': 'Unknown',
            };
            return result;
        }
      }
    } catch (e) {
      return {'Error': 'Failed to get platform version.'};
    }
  }
}

final deviceServiceProvider = Provider(DeviceService.new);
