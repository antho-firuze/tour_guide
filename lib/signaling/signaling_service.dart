import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tour_guide/env/env.dart';
import 'package:tour_guide/model/audience.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/utils/dio_service.dart';

// COMMON SECTION
enum Server { google, meteredCA, twilio, rynest36 }
final serverName = <Server, String>{
  Server.google: "https://www.google.com/",
  Server.meteredCA: "https://www.metered.ca/",
  Server.twilio: "https://www.twilio.com/",
  Server.rynest36: "Rynest-202.73.24.36",
};

// PRESENTER SECTION
final audienceStreamProvider = StreamProvider.family<List<Audience>?, int>((ref, presenterId) async* {
  yield* Supabase.instance.client.from('audience').stream(primaryKey: ['id']).inFilter(
      'presenter_id', [presenterId]).map((jsonList) => jsonList.map(Audience.fromJson).toList());
});

// AUDIENCE SECTION
final livePresenterProvider = StreamProvider<List<Presenter>?>((ref) async* {
  yield* Supabase.instance.client
      .from('presenter')
      .stream(primaryKey: ['id']).map((event) => event.map(Presenter.fromJson).toList());
});

final audienceByIdStreamProvider = StreamProvider.family<List<Audience>?, int>((ref, audienceId) async* {
  yield* Supabase.instance.client.from('audience').stream(primaryKey: ['id']).inFilter(
      'id', [audienceId]).map((jsonList) => jsonList.map(Audience.fromJson).toList());
});

class SignalingSvc {
  Ref ref;
  SignalingSvc(this.ref);

  // COMMON SECTION
  Future<Map<String, dynamic>> fetchConfiguration(Server server) async {
    try {
      Map<String, dynamic> configuration = {};
      switch (server) {
        case Server.google:
          configuration['ice_servers'] = [
            {"url": "stun:stun3.l.google.com:19302", "urls": "stun:stun3.l.google.com:19302"},
          ];
          break;
        case Server.meteredCA:
          final data = {"apiKey": Env.turnApiKey};
          final state = await AsyncValue.guard(() async => await _fetchConfigurationFromMetered(data: data));

          configuration['ice_servers'] = state.value;
          break;
        case Server.twilio:
          final state = await AsyncValue.guard(() async => await _fetchConfigurationFromTwilio());

          configuration = state.value;
          break;
        case Server.rynest36:
          final serverRynest = Env.rynesTurnUrl;
          final username = Env.rynestUsername;
          final password = Env.rynestPassword;
          configuration['ice_servers'] = [
            {"url": "stun:$serverRynest", "urls": "stun:$serverRynest"},
            {
              "url": "turn:$serverRynest",
              "urls": "turn:$serverRynest",
              "username": username,
              "credential": password,
            },
            {
              "url": "turn:$serverRynest?transport=udp",
              "urls": "turn:$serverRynest?transport=udp",
              "username": username,
              "credential": password,
            },
            {
              "url": "turn:$serverRynest?transport=tcp",
              "urls": "turn:$serverRynest?transport=tcp",
              "username": username,
              "credential": password,
            },
          ];
          break;
      }

      return configuration;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future _fetchConfigurationFromMetered({Map<String, dynamic>? data}) async {
    final url = Uri.parse("https://rynest.metered.live").replace(path: '/api/v1/turn/credentials').toString();
    final state = await AsyncValue.guard(() async => await ref.read(dioProvider).get(url, queryParameters: data));

    return state.value?.data;
  }

  Future _fetchConfigurationFromTwilio({Map<String, dynamic>? data}) async {
    final url = Uri.parse("https://api.twilio.com")
        .replace(path: '/2010-04-01/Accounts/${Env.twilioUsername}/Tokens.json')
        .toString();

    final basicAuth = 'Basic ${base64.encode(utf8.encode('${Env.twilioUsername}:${Env.twilioPassword}'))}';
    final options = Options(headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Authorization": basicAuth,
    });
    final state =
        await AsyncValue.guard(() async => await ref.read(dioProvider).post(url, data: data, options: options));

    return state.value?.data;
  }

  // PRESENTER SECTION
  Future createPresenter(Map<dynamic, dynamic> data) async {
    try {
      final result = await Supabase.instance.client
          .from('presenter')
          .upsert(data, onConflict: 'device_id')
          .select()
          .limit(1)
          .single();
      log('createPresenter | ok', name: 'signaling');
      return result;
    } catch (e) {
      log('createPresenter | error | $e', name: 'signaling');
    }
  }

  Future updatePresenter(Map<dynamic, dynamic> data, int presenterId) async {
    try {
      await Supabase.instance.client.from('presenter').update(data).eq('id', presenterId);
      log('updatePresenter | ok', name: 'signaling');
    } catch (e) {
      log('updatePresenter | error', error: e, name: 'signaling');
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

  // AUDIENCE SECTION
  Future createAudience(Map<dynamic, dynamic> data) async {
    try {
      final result = await Supabase.instance.client
          .from('audience')
          .upsert(data, onConflict: 'device_id')
          .select()
          .limit(1)
          .single();
      log('createAudience | ok', name: 'signaling');
      return result;
    } catch (e) {
      log('createAudience | error | $e', name: 'signaling');
    }
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

  Future removeAudienceByPresenterId(int presenterId) async {
    try {
      await Supabase.instance.client.from('audience').delete().eq('presenter_id', presenterId);
      log('removeAudienceByPresenterId | $presenterId', name: 'signaling');
    } catch (e) {
      log('removeAudienceByPresenterId | error', error: e, name: 'signaling');
    }
  }
}

final signalingSvcProvider = Provider(SignalingSvc.new);
