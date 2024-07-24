import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tour_guide/model/audience.dart';
import 'package:tour_guide/model/presenter.dart';

final livePresenterProvider = StreamProvider<List<Presenter>?>((ref) async* {
  yield* Supabase.instance.client
      .from('presenter')
      .stream(primaryKey: ['id']).map((event) => event.map(Presenter.fromJson).toList());
});

final audienceByIdStreamProvider = StreamProvider.family<List<Audience>?, int>((ref, audienceId) async* {
  yield* Supabase.instance.client.from('audience').stream(primaryKey: ['id']).inFilter(
      'id', [audienceId]).map((jsonList) => jsonList.map(Audience.fromJson).toList());
});

class AudienceSvc {
  Ref ref;
  AudienceSvc(this.ref);

  Future<List<Map<String, dynamic>>?> getPresenterCandidates(String identifier) async {
    try {
      final rows = await Supabase.instance.client.from('presenter_candidates').select().eq('device_id', identifier);
      return rows;
    } catch (e) {
      return null;
    }
  }

  Future upsert(Object data) async {
    try {
      final result = await Supabase.instance.client
          .from('audience')
          .upsert(data, onConflict: 'device_id')
          .select()
          .limit(1)
          .single();
      // log('upsert | ok', name: 'audience');
      return result;
    } catch (e) {
      log('upsert | error', error: e, name: 'audience');
    }
  }

  Future upsertState(Object data) async {
    try {
      final result = await Supabase.instance.client
          .from('audience_state')
          .upsert(data, onConflict: 'audience_id')
          .select()
          .limit(1)
          .single();
      log('upsertState | ok', name: 'audience');
      return result;
    } catch (e) {
      log('upsertState | error', error: e, name: 'audience');
    }
  }

  // Future remove(String identifier) async {
  //   try {
  //     await Supabase.instance.client.from('audience').delete().eq('device_id', identifier);
  //     log('remove | ok', name: 'audience');
  //   } catch (e) {
  //     log('remove | error | $e', name: 'audience');
  //   }
  // }
}

final audienceSvcProvider = Provider(AudienceSvc.new);
