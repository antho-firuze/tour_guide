import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tour_guide/model/audience.dart';

final liveAudienceProvider = StreamProvider.family<List<Audience>?, int>((ref, id) async* {
  yield* Supabase.instance.client
      .from('audience')
      .stream(primaryKey: ['id']).inFilter('presenter_id', [id]).map((event) => event.map(Audience.fromJson).toList());
});

final audienceCandidateProvider = StreamProvider.family<List<Map<String, dynamic>>?, String>((ref, identifier) async* {
  yield* Supabase.instance.client.from('audience_candidates').stream(primaryKey: ['id']).inFilter('device_id', [identifier]);
});

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

  Future remove(String identifier) async {
    try {
      await Supabase.instance.client.from('presenter').delete().eq('device_id', identifier);
      log('remove | ok', name: 'presenter');
    } catch (e) {
      log('remove | error | $e', name: 'presenter');
    }
  }
}

final presenterSvcProvider = Provider(PresenterSvc.new);
