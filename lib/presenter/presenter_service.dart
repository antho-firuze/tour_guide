import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenterSvc {
  Ref ref;
  PresenterSvc(this.ref);

  Future upsert(Object data) async {
    try {
      final result = await Supabase.instance.client
          .from('presenter')
          .upsert(data, onConflict: 'device_id')
          .select()
          .limit(1)
          .single();
      log('upsert | ok', name: 'presenter');
      return result;
    } catch (e) {
      log('upsert | error | $e', name: 'presenter');
    }
  }
}

final presenterSvcProvider = Provider(PresenterSvc.new);
