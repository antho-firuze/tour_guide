// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/model/audience.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/signaling/signaling_service.dart';
import 'package:tour_guide/utils/datetime_utils.dart';

// COMMON SECTION
final timeoutProvider = StateProvider<int>((ref) => 10);
final titleProvider = StateProvider<String>((ref) => 'Umrah 2024');
final serverProvider = StateProvider<Server>((ref) => Server.google);
// PRESENTER SECTION
final localRendererProvider = StateProvider<RTCVideoRenderer>((ref) => RTCVideoRenderer());
final isOnlineProvider = StateProvider<bool>((ref) => false);
final presenterProvider = StateProvider<Presenter?>((ref) => null);
// AUDIENCE SECTION
final remoteRendererProvider = StateProvider<RTCVideoRenderer>((ref) => RTCVideoRenderer());
final isConnectedProvider = StateProvider<bool>((ref) => false);
final selectedPresenterProvider = StateProvider<Presenter?>((ref) => null);
final audienceProvider = StateProvider<Audience?>((ref) => null);

class SignalingCtrl {
  Ref ref;
  SignalingCtrl(this.ref);

  // COMMON SECTION
  Map<String, dynamic> _configuration = {};
  int heartbeat = 10; // in seconds
  Timer? _timeoutTimer;
  int connectionTimeout = 10; // in seconds
  void Function()? onTimeout;

  // PRESENTER SECTION
  Map<int, RTCPeerConnection?> _peers = {};
  Map<int, Map<String, dynamic>> _offers = {};
  MediaStream? _localStream;
  ProviderSubscription? _participantSubs;
  // STATE : active | inactive

  // AUDIENCE SECTION
  RTCPeerConnection? _peer;
  Map<String, dynamic> _answer = {};
  MediaStream? _remoteStream;
  ProviderSubscription? _audienceSubs;
  void Function()? onDisconnected;
  void Function()? onFailed;
  void Function(String serverName)? onServerConnectionFailed;
  // STATE : join | offer | answer | connected | leave | inactive

  // COMMON SECTION
  Future _fetchConfiguration() async {
    try {
      log('fetchConfiguration :', name: 'signaling');

      _configuration = await ref.read(signalingSvcProvider).fetchConfiguration(ref.read(serverProvider));

      log('$_configuration', name: 'signaling');
    } catch (e) {
      if (onServerConnectionFailed != null) onServerConnectionFailed!(serverName[ref.read(serverProvider)]!);
    }
  }

  // PRESENTER SECTION
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

  Future<int?> _createRoom(Map<dynamic, dynamic> data) async {
    try {
      data['state'] = 'active';
      final state = await AsyncValue.guard(() async => await ref.read(signalingSvcProvider).createPresenter(data));

      final presenter = Presenter.fromJson(state.value);
      ref.read(presenterProvider.notifier).state = presenter;

      return presenter.id;
    } catch (e) {
      log('_createRoom | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future _waitingAudiences(int presenterId) async {
    log('Waiting Audience...', name: 'signaling');
    _participantSubs = ref.listen(audienceStreamProvider(presenterId), (previous, next) async {
      if (previous == next) return;

      final audiences = next.value;
      if (audiences != null && audiences.isNotEmpty) {
        for (Audience audience in audiences) {
          if (audience.state == 'join') {
            if (_peers[audience.id!] == null) {
              log('peer${audience.id} : Got new Audience', name: 'signaling');
              await _createInstancePeerConnection(audience.id!);
            }
          }

          if (audience.state == 'answer') {
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

          if (['leave', 'inactive'].contains(audience.state)) {
            await _closeInstancePeerConnection(audience.id!);
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

  Future _createInstancePeerConnection(int audienceId) async {
    try {
      log('peer$audienceId : Create Peer Connection : $_configuration', name: 'signaling');
      _peers[audienceId] = await createPeerConnection(_configuration);

      _registerPeersConnectionListener(audienceId);

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

  void _registerPeersConnectionListener(int audienceId) {
    _peers[audienceId]?.onIceConnectionState = (RTCIceConnectionState state) {
      log('peer$audienceId : ICE connection state change: $state', name: 'signaling');
    };

    _peers[audienceId]?.onIceGatheringState = (RTCIceGatheringState state) async {
      log('peer$audienceId : ICE gathering state changed: $state', name: 'signaling');

      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        var data = {
          "offer": _offers[audienceId],
          "state": "offer",
        };
        log('peer$audienceId : Got Local ICE Candidate', name: 'signaling');
        await AsyncValue.guard(() async => await ref.read(signalingSvcProvider).updateAudience(data, audienceId));
      }
    };

    _peers[audienceId]?.onConnectionState = (RTCPeerConnectionState state) async {
      log('peer$audienceId : Connection state change: $state', name: 'signaling');

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        var data = {
          "offer": null,
          "answer": null,
          "state": "connected",
        };
        log('peer$audienceId : Set connection state | connected', name: 'signaling');
        await AsyncValue.guard(() async => await ref.read(signalingSvcProvider).updateAudience(data, audienceId));
      }
    };

    _peers[audienceId]?.onSignalingState = (RTCSignalingState state) {
      log('peer$audienceId : Signaling state change: $state', name: 'signaling');
    };
  }

  Future _closeInstancePeerConnection(int audienceId) async {
    try {
      log('peer$audienceId : closeInstancePeerConnection', name: 'signaling');

      await _peers[audienceId]?.close();
      _peers.remove(audienceId);

      await ref.read(signalingSvcProvider).removeAudience(audienceId);
    } catch (e) {
      log('peer$audienceId : closeInstancePeerConnection | error', error: e, name: 'signaling');
    }
  }

  void _heartbeatPresenter(int presenterId) async {
    log('presenterId$presenterId : heartbeat presenter | start (every $heartbeat seconds)', name: 'signaling');
    await Future.doWhile(() async {
      await Future.delayed(Duration(seconds: heartbeat));

      final data = {"heartbeat": DateTime.now().dbDateTime()};
      await AsyncValue.guard(() async => await ref.read(signalingSvcProvider).updatePresenter(data, presenterId));

      if (ref.read(presenterProvider) == null) {
        log('presenterId$presenterId : heartbeat presenter | stop', name: 'signaling');
        return false;
      }
      // log(':: heartbeat => $time');
      return true;
    });
  }

  Future startMeeting(Map<dynamic, dynamic> data) async {
    try {
      log('startMeeting', name: 'signaling');
      _peers = {};
      _offers = {};

      await _openUserMedia();
      await _fetchConfiguration();

      final presenterId = await _createRoom(data);
      await _waitingAudiences(presenterId!);

      _heartbeatPresenter(presenterId);
    } catch (e) {
      log('startMeeting | error', error: e, name: 'signaling');
      await closeMeeting();
      throw Exception(e.toString());
    }
  }

  Future closeMeeting([int? presenterId]) async {
    try {
      log('closeMeeting', name: 'signaling');

      if (presenterId != null) {
        for (var peer in _peers.entries) {
          await peer.value?.close();
        }

        await ref.read(signalingSvcProvider).removeAudienceByPresenterId(presenterId);
        await ref.read(signalingSvcProvider).removePresenter(presenterId);
        await ref.read(signalingSvcProvider).removePresenterByDeviceId(ref.read(deviceIdProvider));
      }

      log('Closing Subscription', name: 'signaling');
      _participantSubs?.close();

      await _closeUserMedia();
      ref.read(presenterProvider.notifier).state = null;
    } catch (e) {
      log('closeMeeting | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  // AUDIENCE SECTION
  Future<Audience> _addAudience(Presenter presenter) async {
    try {
      log('Add Audience', name: 'signaling');
      final data = {
        "presenter_id": presenter.id,
        "device_id": ref.read(deviceIdProvider),
      };
      final state = await AsyncValue.guard(() async => await ref.read(signalingSvcProvider).createAudience(data));

      final audience = Audience.fromJson(state.value);
      ref.read(audienceProvider.notifier).state = audience;

      return audience;
    } catch (e) {
      log('Add Audience | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future _setRemoteMedia() async {
    log('Init remote media', name: 'signaling');
    ref.read(remoteRendererProvider.notifier).state = RTCVideoRenderer();
    ref.read(remoteRendererProvider.notifier).state.initialize();
  }

  void _setConnectionTimeout(Audience audience) async {
    // Set Timeout connection to peerConnection
    log('set connectionTimeout : $connectionTimeout', name: 'signaling');
    _timeoutTimer = Timer.periodic(Duration(seconds: connectionTimeout), (timer) async {
      if (await _peer?.getConnectionState() == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        log('timeoutTimer | cancelled', name: 'signaling');
        timer.cancel();
      } else {
        log('createPeerConnection | Timeout has occured !', name: 'signaling');
        if (onTimeout != null) onTimeout!();
        timer.cancel();
        await leaveMeeting(audience.id!);
      }
    });
  }

  Future _createPeerConnection(Audience audience) async {
    log('createPeerConnection | $_configuration', name: 'signaling');
    _peer = await createPeerConnection(_configuration);

    _registerPeerConnectionListeners(audience.id!);

    // CANDIDATES
    // _peer!.onIceCandidate = (RTCIceCandidate candidate) async => _answerCandidates.add(candidate.toMap());
    _peer!.onIceCandidate = (RTCIceCandidate candidate) async {
      // _answerCandidates.add(candidate.toMap());
      _answer = (await _peer?.getLocalDescription())?.toMap();
    };

    // ADD REMOTE STREAM
    _peer?.onAddStream = (stream) {
      log('Add remote stream', name: 'signaling');
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

    await _peer?.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    await _peer?.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    // WAITING OFFER RESPONSE
    _audienceSubs = ref.listen(audienceByIdStreamProvider(audience.id!), (previous, next) async {
      if (previous == next) return;

      final audiences = next.value;
      if (audiences != null && audiences.isNotEmpty) {
        Audience audience = audiences[0];
        if (audience.state == 'offer') {
          log('setRemoteDescription', name: 'signaling');
          final offer = RTCSessionDescription(audience.offer!['sdp'], audience.offer!['type']);
          await _peer?.setRemoteDescription(offer);

          log('Create Answer', name: 'signaling');
          final createdAnswer = await _peer?.createAnswer();
          _answer = createdAnswer!.toMap();

          log('setLocalDescription', name: 'signaling');
          await _peer?.setLocalDescription(createdAnswer);
        }

        // if (audience.offerCandidate != null && audience.answerCandidate == null) {
        //   log('Got remote ICE Candidate | length = ${audience.offerCandidate?.length} ', name: 'signaling');
        //   for (var item in audience.offerCandidate!) {
        //     log('Adding remote ICE candidate', name: 'signaling');
        //     final candidate = RTCIceCandidate(item['candidate'], item['sdpMid'], item['sdpMLineIndex']);
        //     await _peer?.addCandidate(candidate);
        //   }
        // }
      }
    });
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
          "state": "answer",
        };
        log('Got Local ICE Candidate', name: 'signaling');
        await ref.read(signalingSvcProvider).updateAudience(data, id);
      }
    };

    _peer?.onConnectionState = (RTCPeerConnectionState state) async {
      log('Connection state change: $state', name: 'signaling');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        ref.read(isConnectedProvider.notifier).state = true;
      }

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        await leaveMeeting(id);
        if (onFailed != null) onFailed!();
      }

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        await leaveMeeting(id);
        if (onDisconnected != null) onDisconnected!();
      }
    };

    _peer?.onSignalingState = (RTCSignalingState state) {
      log('Signaling state change: $state', name: 'signaling');
    };
  }

  void _heartbeatAudience(int audienceId) async {
    log('audienceId$audienceId : heartbeat audience | start (every $heartbeat seconds)', name: 'signaling');
    await Future.doWhile(() async {
      await Future.delayed(Duration(seconds: heartbeat));

      final data = {"heartbeat": DateTime.now().dbDateTime()};
      await AsyncValue.guard(() async => await ref.read(signalingSvcProvider).updateAudience(data, audienceId));

      if (ref.read(presenterProvider) == null) {
        log('audienceId$audienceId : heartbeat audience | stop', name: 'signaling');
        return false;
      }
      // log(':: heartbeat => $time');
      return true;
    });
  }

  Future joinMeeting(Presenter presenter) async {
    try {
      log('Join Meeting', name: 'signaling');
      await _fetchConfiguration();
      await _setRemoteMedia();

      final audience = await _addAudience(presenter);

      _setConnectionTimeout(audience);

      await _createPeerConnection(audience);

      _heartbeatAudience(audience.id!);

      ref.read(selectedPresenterProvider.notifier).state = presenter;
    } catch (e) {
      log('Join Meeting | error', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future leaveMeeting([int? audienceId]) async {
    try {
      log('Leave Meeting', name: 'signaling');

      _timeoutTimer?.cancel();

      await _peer?.close();
      _peer = null;

      ref.read(remoteRendererProvider.notifier).state.srcObject = null;
      ref.read(remoteRendererProvider.notifier).state.dispose();

      if (audienceId != null) {
        final data = {"state": "leave"};
        await AsyncValue.guard(() async => await ref.read(signalingSvcProvider).updateAudience(data, audienceId));
      }

      log('Closing Subscription', name: 'signaling');
      _audienceSubs?.close();

      ref.read(isConnectedProvider.notifier).state = false;
      ref.read(selectedPresenterProvider.notifier).state = null;
    } catch (e) {
      log('Leave Meeting | error', error: e, name: 'signaling');
    }
  }
}

final signalingCtrlProvider = Provider(SignalingCtrl.new);
