import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tour_guide/audience/audience_controller.dart';
import 'package:tour_guide/audience/audience_service.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/model/presenter.dart';
import 'package:tour_guide/signaling/signaling_service.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

final remoteRendererProvider = StateProvider<RTCVideoRenderer>((ref) => RTCVideoRenderer());

class Signaling2Ctrl {
  Ref ref;
  Signaling2Ctrl(this.ref);

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
  MediaStream? remoteStream;

  RTCIceConnectionState? iceConnectionState;
  RTCIceGatheringState? iceGatheringState;

  Future initialize() async {
    final videoRenderer = RTCVideoRenderer();
    await videoRenderer.initialize();
    ref.read(remoteRendererProvider.notifier).state = videoRenderer;
  }

  Future<bool> join(Presenter presenter) async {
    await initialize();

    try {
      log('createPeerConnection | $configuration', name: 'signaling2');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      // CANDIDATES
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
        var data = {
          "audience_id": ref.watch(audienceProvider)!.id,
          "device_id": ref.read(deviceIdProvider),
          "candidate": candidate.toMap(),
        };
        log('Got ICE Candidate', name: 'signaling2');
        await ref.read(signalingServiceProvider).addCandidate(CandidateType.audience, data);
      };

      // REMOTE STREAM
      peerConnection?.onAddStream = (stream) {
        log('Add remote stream: $stream', name: 'signaling2');
        ref.read(remoteRendererProvider.notifier).state.srcObject = stream;
      };

      // REMOTE STREAM
      peerConnection?.onTrack = (RTCTrackEvent event) {
        log('Got remote track: ${event.streams[0]}', name: 'signaling2');
        event.streams[0].getTracks().forEach((track) async {
          log('Add a track to the remoteStream $track', name: 'signaling2');
          await remoteStream?.addTrack(track);
        });
      };

      await peerConnection?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await peerConnection?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // ANSWER
      final offer = presenter.offer;
      if (offer != null) {
        log('peerConnection?.setRemoteDescription', name: 'signaling2');
        await peerConnection?.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );

        log('peerConnection?.createAnswer', name: 'signaling2');
        final answer = await peerConnection?.createAnswer();

        log('peerConnection?.setLocalDescription', name: 'signaling2');
        await peerConnection?.setLocalDescription(answer!);

        var data = {
          "device_id": ref.read(deviceIdProvider),
          "answer": answer!.toMap(),
        };
        log('upsert answer | $data', name: 'signaling2');
        await ref.read(audienceSvcProvider).upsert(data);
      }

      log('Going to get presenter candidate', name: 'signaling2');
      final candidates = await ref.read(audienceSvcProvider).getPresenterCandidates(presenter.deviceId);
      if (candidates != null && candidates.isNotEmpty) {
        log('Got new remote ICE candidate', name: 'signaling2');
        for (var row in candidates) {
          final candidate = row['candidate'];
          log('Adding remote ICE candidate', name: 'signaling2');
          await peerConnection?.addCandidate(
            RTCIceCandidate(candidate['candidate'], candidate['sdpMid'], candidate['sdpMLineIndex']),
          );
        }
      }

      return true;
    } catch (e) {
      log('createPeerConnection', error: e, name: 'signaling2');
      throw Exception(e.toString());
    }
  }

  Future<bool> close() async {
    try {
      await peerConnection?.close();
      peerConnection = null;

      ref.read(remoteRendererProvider.notifier).state.srcObject = null;
      ref.read(remoteRendererProvider.notifier).state.dispose();

      await ref.read(signalingServiceProvider).removeCandidate(CandidateType.audience, ref.read(deviceIdProvider));
      log('close | ok', name: 'signaling2');
      return true;
    } catch (e) {
      log('close', error: e, name: 'signaling2');
      return false;
    }
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      log('ICE connection state change: $state', name: 'signaling2');
      iceConnectionState = state;
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      log('ICE gathering state changed: $state', name: 'signaling2');
      iceGatheringState = state;
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      log('Connection state change: $state', name: 'signaling2');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      log('Signaling state change: $state', name: 'signaling2');
    };
  }
}

final signaling2CtrlProvider = Provider(Signaling2Ctrl.new);
