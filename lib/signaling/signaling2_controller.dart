// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tour_guide/audience/audience_service.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/env/env.dart';
import 'package:tour_guide/model/audience.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/signaling/signaling_service.dart';
import 'package:tour_guide/utils/datetime_utils.dart';

enum Server { google, meteredCA, twilio }

final serverName = <Server, String>{
  Server.google: "https://www.google.com/",
  Server.meteredCA: "https://www.metered.ca/",
  Server.twilio: "https://www.twilio.com/",
};

final remoteRendererProvider = StateProvider<RTCVideoRenderer>((ref) => RTCVideoRenderer());
final isConnectedProvider = StateProvider<bool>((ref) => false);
final selectedPresenterProvider = StateProvider<Presenter?>((ref) => null);
final audienceProvider = StateProvider<Audience?>((ref) => null);
final timeoutProvider = StateProvider<int>((ref) => 10);
final serverProvider = StateProvider<Server>((ref) => Server.google);

class Signaling2Ctrl {
  Ref ref;
  Signaling2Ctrl(this.ref);

  Map<String, dynamic> _configuration = {
    'ice_servers': [
      {"url": "stun:stun3.l.google.com:19302", "urls": "stun:stun3.l.google.com:19302"},
    ],
  };

  RTCPeerConnection? _peer;
  Map<String, dynamic> _answer = {};
  List<Map<String, dynamic>> _answerCandidates = [];

  MediaStream? _remoteStream;

  ProviderSubscription? _audienceSubs;

  Timer? _timeoutTimer;
  int connectionTimeout = 10; // in seconds
  void Function()? onTimeout;

  RTCPeerConnectionState? _peerConnectionState;
  void Function()? onDisconnected;
  void Function()? onFailed;
  void Function(String serverName)? onServerConnectionFailed;

  Future<Audience> _addAudience(Presenter presenter) async {
    try {
      log('Add Audience', name: 'signaling');
      final data = {
        "presenter_id": presenter.id,
        "device_id": ref.read(deviceIdProvider),
      };
      final state = await AsyncValue.guard(() async => await ref.read(audienceSvcProvider).upsert(data));

      final audience = Audience.fromJson(state.value);
      ref.read(audienceProvider.notifier).state = audience;

      return audience;
    } catch (e) {
      log('Add Audience | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future _setAudienceState(Audience audience) async {
    try {
      log('Set Audience State', name: 'signaling');
      final data2 = {
        "audience_id": audience.id,
        "presenter_id": audience.presenterId,
        "heartbeat": DateTime.now().dbDateTime(),
      };
      await AsyncValue.guard(() async => await ref.read(audienceSvcProvider).upsertState(data2));
    } catch (e) {
      log('Set Audience State | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future _setRemoteMedia() async {
    log('Init remote media', name: 'signaling');
    ref.read(remoteRendererProvider.notifier).state = RTCVideoRenderer();
    ref.read(remoteRendererProvider.notifier).state.initialize();
  }

  Future _fetchConfiguration() async {
    try {
      log('fetchConfiguration :', name: 'signaling');
      switch (ref.read(serverProvider)) {
        case Server.google:
          _configuration['ice_servers'] = [
            {"url": "stun:stun3.l.google.com:19302", "urls": "stun:stun3.l.google.com:19302"},
          ];
          break;
        case Server.meteredCA:
          final data = {"apiKey": Env.turnApiKey};
          final state = await AsyncValue.guard(
              () async => await ref.read(signalingServiceProvider).fetchConfigurationFromMetered(data: data));

          _configuration['ice_servers'] = state.value;
          break;
        case Server.twilio:
          final state = await AsyncValue.guard(
              () async => await ref.read(signalingServiceProvider).fetchConfigurationFroTwilio());

          _configuration = state.value;
          break;
      }

      log('$_configuration', name: 'signaling');
    } catch (e) {
      if (onServerConnectionFailed != null) onServerConnectionFailed!(serverName[ref.read(serverProvider)]!);
    }
  }

  void _setConnectionTimeout(Audience audience) async {
    // Set Timeout connection to peerConnection
    log('set connectionTimeout : $connectionTimeout', name: 'signaling');
    _timeoutTimer = Timer.periodic(Duration(seconds: connectionTimeout), (timer) async {
      if (_peerConnectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        log('timeoutTimer | cancelled', name: 'signaling');
        timer.cancel();
      } else {
        log('createPeerConnection | Timeout has occured !', name: 'signaling');
        if (onTimeout != null) onTimeout!();
        timer.cancel();
        await close(audience.id!);
      }
    });
  }

  Future _createPeerConnection(
    Audience audience,
  ) async {
    log('createPeerConnection | $_configuration', name: 'signaling');
    _peer = await createPeerConnection(_configuration);

    _registerPeerConnectionListeners(audience.id!);

    // CANDIDATES
    _peer!.onIceCandidate = (RTCIceCandidate candidate) async => _answerCandidates.add(candidate.toMap());

    // ADD REMOTE STREAM
    _peer?.onAddStream = (stream) {
      log('Add remote stream: $stream', name: 'signaling');
      ref.read(remoteRendererProvider.notifier).state.srcObject = stream;
    };

    // ADD TRACK FROM REMOTE STREAM
    _peer?.onTrack = (RTCTrackEvent event) {
      // log('Got remote track: ${event.streams[0]}', name: 'signaling');
      event.streams[0].getTracks().forEach((track) async {
        log('Add a track from remote stream $track', name: 'signaling');
        await _remoteStream?.addTrack(track);
      });
    };

    // WAITING OFFER RESPONSE
    _audienceSubs = ref.listen(audienceByIdStreamProvider(audience.id!), (previous, next) async {
      if (previous == next) return;

      final audiences = next.value;
      if (audiences != null && audiences.isNotEmpty) {
        Audience audience = audiences[0];
        if (audience.offer != null && audience.answer == null) {
          log('setRemoteDescription', name: 'signaling');
          final offer = RTCSessionDescription(audience.offer!['sdp'], audience.offer!['type']);
          await _peer?.setRemoteDescription(offer);

          log('Create Answer', name: 'signaling');
          final createdAnswer = await _peer?.createAnswer();
          _answer = createdAnswer!.toMap();

          log('setLocalDescription', name: 'signaling');
          await _peer?.setLocalDescription(createdAnswer);
        }

        if (audience.offerCandidate != null && audience.answerCandidate == null) {
          log('Got remote ICE Candidate | length = ${audience.offerCandidate?.length} ', name: 'signaling');
          for (var item in audience.offerCandidate!) {
            log('Adding remote ICE candidate', name: 'signaling');
            final candidate = RTCIceCandidate(item['candidate'], item['sdpMid'], item['sdpMLineIndex']);
            await _peer?.addCandidate(candidate);
          }
        }
      }
    });
  }

  Future join(Presenter presenter) async {
    try {
      log('join presenter', name: 'signaling');
      await _fetchConfiguration();
      await _setRemoteMedia();

      final audience = await _addAudience(presenter);
      await _setAudienceState(audience);

      _setConnectionTimeout(audience);

      await _createPeerConnection(audience);

      ref.read(selectedPresenterProvider.notifier).state = presenter;
    } catch (e) {
      log('join presenter | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future close([int? audienceId]) async {
    try {
      log('Closing Connection', name: 'signaling');

      _timeoutTimer?.cancel();

      await _peer?.close();
      _peer = null;

      ref.read(remoteRendererProvider.notifier).state.srcObject = null;
      ref.read(remoteRendererProvider.notifier).state.dispose();

      if (audienceId != null) {
        final data2 = {
          "audience_id": audienceId,
          "is_closed": true,
        };
        await AsyncValue.guard(() async => await ref.read(audienceSvcProvider).upsertState(data2));
      }

      log('Closing Subscription', name: 'signaling');
      _audienceSubs?.close();

      ref.read(isConnectedProvider.notifier).state = false;
      ref.read(selectedPresenterProvider.notifier).state = null;
    } catch (e) {
      log('Closing Connection | error', error: e, name: 'signaling');
    }
  }

  void _registerPeerConnectionListeners(int id) {
    _peer?.onIceConnectionState = (RTCIceConnectionState state) {
      log('ICE connection state change: $state', name: 'signaling');
    };

    _peer?.onIceGatheringState = (RTCIceGatheringState state) async {
      log('ICE gathering state changed: $state', name: 'signaling');

      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        var data = {
          "answer": _answer,
          "answer_candidate": _answerCandidates,
        };
        log('Got ICE Candidate', name: 'signaling');
        await ref.read(signalingServiceProvider).updateAudience(data, id);
      }
    };

    _peer?.onConnectionState = (RTCPeerConnectionState state) async {
      log('Connection state change: $state', name: 'signaling');
      _peerConnectionState = state;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        ref.read(isConnectedProvider.notifier).state = true;
      }

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        await close(id);
        if (onFailed != null) onFailed!();
      }

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        await close(id);
        if (onDisconnected != null) onDisconnected!();
      }
    };

    _peer?.onSignalingState = (RTCSignalingState state) {
      log('Signaling state change: $state', name: 'signaling');
    };
  }
}

final signaling2CtrlProvider = Provider(Signaling2Ctrl.new);
