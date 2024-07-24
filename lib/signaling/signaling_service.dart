import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tour_guide/env/env.dart';
import 'package:tour_guide/model/audience.dart';
import 'package:tour_guide/utils/dio_service.dart';

final audienceStreamProvider = StreamProvider.family<List<Audience>?, int>((ref, presenterId) async* {
  yield* Supabase.instance.client.from('audience').stream(primaryKey: ['id']).inFilter(
      'presenter_id', [presenterId]).map((jsonList) => jsonList.map(Audience.fromJson).toList());
});

final audienceStateStreamProvider = StreamProvider.family<List<AudienceState>?, int>((ref, presenterId) async* {
  yield* Supabase.instance.client.from('audience_state').stream(primaryKey: ['id']).inFilter(
      'presenter_id', [presenterId]).map((jsonList) => jsonList.map(AudienceState.fromJson).toList());
});

class SignalingService {
  Ref ref;
  SignalingService(this.ref);

  Future fetchConfigurationFromMetered({Map<String, dynamic>? data}) async {
    final url = Uri.parse("https://rynest.metered.live").replace(path: '/api/v1/turn/credentials').toString();
    final state = await AsyncValue.guard(() async => await ref.read(dioProvider).get(url, queryParameters: data));

    return state.value?.data;
  }

  Future fetchConfigurationFroTwilio({Map<String, dynamic>? data}) async {
    final url = Uri.parse("https://api.twilio.com")
        .replace(path: '/2010-04-01/Accounts/${Env.twilioUsername}/Tokens.json')
        .toString();

    final basicAuth = 'Basic ${base64.encode(utf8.encode('${Env.twilioUsername}:${Env.twilioPassword}'))}';
    final options = Options(headers: {"Authorization": basicAuth});
    final state = await AsyncValue.guard(() async => await ref.read(dioProvider).post(url, options: options));

    return state.value?.data;
  }

  Future updateAudience(Map<dynamic, dynamic> data, int audienceId) async {
    try {
      await Supabase.instance.client.from('audience').update(data).eq('id', audienceId);
      log('updateAudience | ok', name: 'signaling');
    } catch (e) {
      log('updateAudience | error', error: e, name: 'signaling');
    }
  }

  Future removeAudience(int audienceId) async {
    try {
      await Supabase.instance.client.from('audience').delete().eq('id', audienceId);
      log('removeAudience | $audienceId', name: 'signaling');
    } catch (e) {
      log('removeAudience | error', error: e, name: 'signaling');
    }
  }

  Future removeAudienceState(int audienceId) async {
    try {
      await Supabase.instance.client.from('audience_state').delete().eq('audience_id', audienceId);
      log('removeAudienceState | $audienceId', name: 'signaling');
    } catch (e) {
      log('removeAudienceState | error', error: e, name: 'signaling');
    }
  }

  Future removePresenter(int presenterId) async {
    try {
      await Supabase.instance.client.from('presenter').delete().eq('id', presenterId);
      log('removePresenter | $presenterId', name: 'signaling');
    } catch (e) {
      log('removePresenter | error', error: e, name: 'signaling');
    }
  }

  Future removePresenterByDeviceId(String deviceId) async {
    try {
      await Supabase.instance.client.from('presenter').delete().eq('device_id', deviceId);
      log('removePresenterByDeviceId | $deviceId', name: 'signaling');
    } catch (e) {
      log('removePresenterByDeviceId | error', error: e, name: 'signaling');
    }
  }

  Future removeAudienceByPresenterId(int presenterId) async {
    try {
      await Supabase.instance.client.from('audience').delete().eq('presenter_id', presenterId);
      log('removeAudienceByPresenterId | $presenterId', name: 'signaling');
    } catch (e) {
      log('removeAudienceByPresenterId | error', error: e, name: 'signaling');
    }
  }

  Future removeAudienceStateByPresenterId(int presenterId) async {
    try {
      await Supabase.instance.client.from('audience_state').delete().eq('presenter_id', presenterId);
      log('removeAudienceStateByPresenterId | $presenterId', name: 'signaling');
    } catch (e) {
      log('removeAudienceStateByPresenterId | error', error: e, name: 'signaling');
    }
  }
}

final signalingServiceProvider = Provider(SignalingService.new);
