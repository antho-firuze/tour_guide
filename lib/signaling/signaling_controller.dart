import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/presenter/presenter_service.dart';
import 'package:tour_guide/signaling/signaling_service.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

final localRendererProvider = StateProvider<RTCVideoRenderer>((ref) => RTCVideoRenderer());

class SignalingCtrl {
  Ref ref;
  SignalingCtrl(this.ref);

  // Map<String, dynamic> configuration = {
  //   'iceServers': [
  //     {
  //       'urls': [
  //         'stun:stun.l.google.com:19302',
  //         'stun:stun1.l.google.com:19302',
  //         'stun:stun2.l.google.com:19302',
  //         'stun:stun3.l.google.com:19302',
  //         'stun:stun4.l.google.com:19302',
  //       ]
  //     }
  //   ],
  //   'iceTransportPolicy': 'relay',
  //   'sdpSemantics': 'uinified-plan',
  // };

  Map<String, dynamic> configuration = {
    'ice_servers': [
      {"url": "stun:stun3.l.google.com:19302", "urls": "stun:stun3.l.google.com:19302"},
    ],
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  ProviderSubscription? liveAudienceSubs;
  ProviderSubscription? audienceCandidatesSubs;

  Future initialize() async {
    final videoRenderer = RTCVideoRenderer();
    await videoRenderer.initialize();
    ref.read(localRendererProvider.notifier).state = videoRenderer;
  }

  Future<bool> create(Presenter presenter) async {
    await initialize();

    try {
      log('createPeerConnection | $configuration', name: 'signaling');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      // CANDIDATES
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
        var data = {
          "presenter_id": presenter.id,
          "device_id": ref.read(deviceIdProvider),
          "candidate": candidate.toMap(),
        };
        log('Got ICE Candidate', name: 'signaling');
        await ref.read(signalingServiceProvider).addCandidate(CandidateType.presenter, data);
      };

      // LOCAL STREAM
      localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});

      ref.read(localRendererProvider.notifier).state.srcObject = localStream;

      localStream?.getTracks().forEach((track) async {
        log('peerConnection?.addTrack | $track', name: 'signaling');
        await peerConnection?.addTrack(track, localStream!);
      });

      // OFFER
      log('Create Offer', name: 'signaling');
      final offer = await peerConnection!.createOffer();
      var data = {
        "device_id": ref.read(deviceIdProvider),
        "offer": offer.toMap(),
      };
      log('Upsert Offer | $data', name: 'signaling');
      await ref.read(presenterSvcProvider).upsert(data);

      log('setLocalDescription', name: 'signaling');
      await peerConnection?.setLocalDescription(offer);

      // REMOTE STREAM
      // peerConnection!.onTrack = (RTCTrackEvent event) {
      //   event.streams[0].getTracks().forEach((track) {
      //     log('Add a track to the remoteStream $track', name: 'signaling');
      //     remoteStream?.addTrack(track);
      //   });
      // };

      log('Waiting for audience....', name: 'signaling');
      liveAudienceSubs = ref.listen(liveAudienceProvider(presenter.id!), (previous, next) async {
        final audiences = next.value;
        if (audiences != null && audiences.isNotEmpty) {
          for (var audience in audiences) {
            if (audience.answer != null) {
              log('Count Audience | ${audiences.length} (had ${audience.answer!['type']})', name: 'signaling');
              var answer = RTCSessionDescription(audience.answer!['sdp'], audience.answer!['type']);
              log('setRemoteDescription', name: 'signaling');
              await peerConnection?.setRemoteDescription(answer);

              // log('Waiting for audience candidate....', name: 'signaling');
              // audienceCandidatesSubs = ref.listen(audienceCandidateProvider(audience.deviceId), (previous, next) async {
              //   List<Map<String, dynamic>>? candidates = next.value;
              //   log('Got new remote ICE candidate | ${candidates?.length}', name: 'signaling');
              //   if (candidates != null && candidates.isNotEmpty) {
              //     for (var row in candidates) {
              //       final candidate = row['candidate'];
              //       await peerConnection?.addCandidate(
              //         RTCIceCandidate(candidate['candidate'], candidate['sdpMid'], candidate['sdpMLineIndex']),
              //       );
              //       log('Adding remote ICE candidate', name: 'signaling');
              //     }
              //   }
              // });
            }
          }
        } else {
          log('Count Audience | ${audiences?.length}', name: 'signaling');
        }
      });

      return true;
    } catch (e) {
      log('createPeerConnection', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future<bool> close() async {
    try {
      log('Signaling Close', name: 'signaling');

      await localStream?.dispose();
      localStream = null;
      await peerConnection?.close();
      peerConnection = null;
      ref.read(localRendererProvider.notifier).state.srcObject = null;
      await ref.read(localRendererProvider.notifier).state.dispose();

      await ref.read(signalingServiceProvider).removeCandidate(CandidateType.presenter, ref.read(deviceIdProvider));

      log('Closing subscription', name: 'signaling');
      liveAudienceSubs?.close();
      audienceCandidatesSubs?.close();

      return true;
    } catch (e) {
      log('close', error: e, name: 'signaling');
      return false;
    }
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      log('ICE connection state change: $state', name: 'signaling');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      log('ICE gathering state changed: $state', name: 'signaling');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      log('Connection state change: $state', name: 'signaling');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      log('Signaling state change: $state', name: 'signaling');
    };
  }
}

final signalingCtrlProvider = Provider(SignalingCtrl.new);
