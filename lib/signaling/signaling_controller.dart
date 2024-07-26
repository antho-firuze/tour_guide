// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/env/env.dart';
import 'package:tour_guide/model/audience.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/presenter/presenter_service.dart';
import 'package:tour_guide/signaling/signaling_service.dart';

enum Server { google, meteredCA, twilio, rynest36 }

final serverName = <Server, String>{
  Server.google: "https://www.google.com/",
  Server.meteredCA: "https://www.metered.ca/",
  Server.twilio: "https://www.twilio.com/",
  Server.rynest36: "Rynest-202.73.24.36",
};

final titleProvider = StateProvider<String>((ref) => 'Umrah 2024');
final localRendererProvider = StateProvider<RTCVideoRenderer>((ref) => RTCVideoRenderer());
final isOnlineProvider = StateProvider<bool>((ref) => false);
final presenterProvider = StateProvider<Presenter?>((ref) => null);
final timeoutProvider = StateProvider<int>((ref) => 10);
final serverProvider = StateProvider<Server>((ref) => Server.google);

class SignalingCtrl {
  Ref ref;
  SignalingCtrl(this.ref);

  Map<String, dynamic> _configuration = {
    'ice_servers': [
      {"url": "stun:stun3.l.google.com:19302", "urls": "stun:stun3.l.google.com:19302"},
    ],
  };

  Map<int, RTCPeerConnection?> _peers = {};
  Map<int, Map<String, dynamic>> _offers = {};
  // Map<int, List<Map<String, dynamic>>> _offerCandidates = {};

  MediaStream? _localStream;

  ProviderSubscription? _audienceSubs;
  ProviderSubscription? _audienceStateSubs;

  void Function()? onTimeout;
  void Function(String serverName)? onServerConnectionFailed;

  Future _openUserMedia() async {
    log('openUserMedia', name: 'signaling');
    ref.read(localRendererProvider.notifier).state = RTCVideoRenderer();
    ref.read(localRendererProvider.notifier).state.initialize();
    // LOCAL STREAM
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
    ref.read(localRendererProvider.notifier).state.srcObject = _localStream;

    // SET ONLINE TRUE
    log('Online : true', name: 'signaling');
    ref.read(isOnlineProvider.notifier).state = true;
  }

  Future _closeUserMedia() async {
    log('closeUserMedia', name: 'signaling');
    await _localStream?.dispose();
    _localStream = null;
    ref.read(localRendererProvider.notifier).state.srcObject = null;
    await ref.read(localRendererProvider.notifier).state.dispose();

    // SET ONLINE FALSE
    log('Online : false', name: 'signaling');
    ref.read(isOnlineProvider.notifier).state = false;
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
          final data = {"ttl": 3600};
          final state = await AsyncValue.guard(
              () async => await ref.read(signalingServiceProvider).fetchConfigurationFroTwilio(data: data));

          _configuration = state.value;
          break;
        case Server.rynest36:
          final serverRynest = Env.rynesTurnUrl;
          final username = Env.rynestUsername;
          final password = Env.rynestPassword;
          _configuration['ice_servers'] = [
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

      log('$_configuration', name: 'signaling');
    } catch (e) {
      if (onServerConnectionFailed != null) onServerConnectionFailed!(serverName[ref.read(serverProvider)]!);
    }
  }

  Future<int?> _createRoom(Object data) async {
    try {
      final state = await AsyncValue.guard(() async => await ref.read(presenterSvcProvider).upsert(data));

      final presenter = Presenter.fromJson(state.value);
      ref.read(presenterProvider.notifier).state = presenter;

      return presenter.id;
    } catch (e) {
      log('_createRoom | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future start(Object data) async {
    try {
      _peers = {};
      _offers = {};
      // _offerCandidates = {};

      await _openUserMedia();
      await _fetchConfiguration();

      final presenterId = await _createRoom(data);
      await _waitingAudiences(presenterId!);
      // await _listeningAudienceState(presenterId);
    } catch (e) {
      log('start | error', error: e, name: 'signaling');
      await closeAllPeerConnection();
      throw Exception(e.toString());
    }
  }

  Future _waitingAudiences(int presenterId) async {
    log('Waiting Audience...', name: 'signaling');
    _audienceSubs = ref.listen(audienceStreamProvider(presenterId), (previous, next) async {
      if (previous == next) return;

      final audiences = next.value;
      if (audiences != null && audiences.isNotEmpty) {
        for (Audience audience in audiences) {
          // log('offer : ${audience.offer}', name: 'debuging');
          // log('offerCandidate : ${audience.offerCandidate?.length}', name: 'debuging');
          // log('answer : ${audience.answer}', name: 'debuging');
          // log('answerCandidate : ${audience.answerCandidate?.length}', name: 'debuging');

          if (audience.offer == null) {
            if (_peers[audience.id!] == null) {
              log('peer${audience.id} : Got new Audience', name: 'signaling');
              await _createInstancePeerConnection(audience.id!);
            }
          }

          if (audience.answer != null) {
            if (await _peers[audience.id!]?.getRemoteDescription() == null) {
              log('peer${audience.id} : Delayed answer...', name: 'signaling');
              await Future.delayed(const Duration(seconds: 3));
              // log('Count Audiences | ${audiences.length}', name: 'signaling');
              log('peer${audience.id} : Got answer from Audience', name: 'signaling');

              log('peer${audience.id} : setRemoteDescription', name: 'signaling');
              var answer = RTCSessionDescription(audience.answer!['sdp'], audience.answer!['type']);
              await _peers[audience.id!]!.setRemoteDescription(answer);
            }
          }

          // if (audience.answerCandidate != null) {
          //   log('Got remote ICE Candidate | length = ${audience.answerCandidate?.length} ', name: 'signaling');
          //   for (var item in audience.answerCandidate!) {
          //     log('peer${audience.id} : Adding remote ICE candidate', name: 'signaling');
          //     final candidate = RTCIceCandidate(item['candidate'], item['sdpMid'], item['sdpMLineIndex']);
          //     await _peers[audience.id!]?.addCandidate(candidate);
          //   }
          // }
        }
      }
    });
  }

  Future _listeningAudienceState(int presenterId) async {
    _audienceStateSubs = ref.listen(audienceStateStreamProvider(presenterId), (previous, next) async {
      final rows = next.value;
      if (rows != null && rows.isNotEmpty) {
        for (AudienceState state in rows) {
          if (state.isClosed) {
            await _closeInstancePeerConnection(state.audienceId!);
          }
        }
      }
    });
  }

  Future _createInstancePeerConnection(int audienceId) async {
    try {
      log('peer$audienceId : Create Peer Connection : $_configuration', name: 'signaling');
      _peers[audienceId] = await createPeerConnection(_configuration);

      _registerPeerConnectionListeners(audienceId);

      // CANDIDATES
      // _offerCandidates[audienceId] = [];
      // _peers[audienceId]?.onIceCandidate =
      //     (RTCIceCandidate candidate) async => _offerCandidates[audienceId]!.add(candidate.toMap());
      _peers[audienceId]?.onIceCandidate = (RTCIceCandidate candidate) async {
        // _offerCandidates[audienceId]!.add(candidate.toMap());
        _offers[audienceId] = (await _peers[audienceId]?.getLocalDescription())?.toMap();
      };

      // ADD TRACK FROM LOCAL STREAM
      log('peer$audienceId : addTrack from local Stream', name: 'signaling');
      _localStream?.getTracks().forEach((track) async => await _peers[audienceId]?.addTrack(track, _localStream!));

      await _peers[audienceId]?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly),
      );

      await _peers[audienceId]?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly),
      );

      // CREATE OFFER
      log('peer$audienceId : Create Offer', name: 'signaling');
      final offer = await _peers[audienceId]?.createOffer();

      // SET LOCAL DESCRIPTION
      log('peer$audienceId : setLocalDescription', name: 'signaling');
      await _peers[audienceId]?.setLocalDescription(offer!);
      _offers[audienceId] = offer!.toMap();
    } catch (e) {
      log('peer$audienceId : createInstancePeerConnection | error', error: e, name: 'signaling');
    }
  }

  Future _closeInstancePeerConnection(int audienceId) async {
    try {
      log('peer$audienceId : closeInstancePeerConnection', name: 'signaling');

      await _peers[audienceId]?.close();
      _peers.remove(audienceId);

      await ref.read(signalingServiceProvider).removeAudience(audienceId);
      await ref.read(signalingServiceProvider).removeAudienceState(audienceId);
    } catch (e) {
      log('peer$audienceId : closeInstancePeerConnection | error', error: e, name: 'signaling');
    }
  }

  Future closeAllPeerConnection([int? presenterId]) async {
    try {
      log('closeAllPeerConnection', name: 'signaling');

      if (presenterId != null) {
        for (var peer in _peers.entries) {
          await peer.value?.close();
        }

        await ref.read(signalingServiceProvider).removeAudienceByPresenterId(presenterId);
        await ref.read(signalingServiceProvider).removeAudienceStateByPresenterId(presenterId);
        await ref.read(signalingServiceProvider).removePresenter(presenterId);
        await ref.read(signalingServiceProvider).removePresenterByDeviceId(ref.read(deviceIdProvider));
      }

      log('Closing Subscription', name: 'signaling');
      _audienceSubs?.close();
      _audienceStateSubs?.close();

      await _closeUserMedia();
      ref.read(presenterProvider.notifier).state = null;
    } catch (e) {
      log('closeAllPeerConnection | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  void _registerPeerConnectionListeners(int id) {
    _peers[id]?.onIceConnectionState = (RTCIceConnectionState state) {
      log('peer$id : ICE connection state change: $state', name: 'signaling');
    };

    _peers[id]?.onIceGatheringState = (RTCIceGatheringState state) async {
      log('peer$id : ICE gathering state changed: $state', name: 'signaling');

      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        var data = {
          "offer": _offers[id],
          // "offer_candidate": _offerCandidates[id],
        };
        log('peer$id : Got Local ICE Candidate', name: 'signaling');
        log('peer$id : ${_offers[id]}', name: 'signaling');
        await AsyncValue.guard(() async => await ref.read(signalingServiceProvider).updateAudience(data, id));
      }
    };

    _peers[id]?.onConnectionState = (RTCPeerConnectionState state) {
      log('peer$id : Connection state change: $state', name: 'signaling');
    };

    _peers[id]?.onSignalingState = (RTCSignalingState state) {
      log('peer$id : Signaling state change: $state', name: 'signaling');
    };
  }
}

final signalingCtrlProvider = Provider(SignalingCtrl.new);
