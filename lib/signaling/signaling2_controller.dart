import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tour_guide/audience/audience_controller.dart';
import 'package:tour_guide/audience/audience_service.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/signaling/signaling_service.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

final remoteRendererProvider = StateProvider<RTCVideoRenderer>((ref) => RTCVideoRenderer());

class Signaling2Ctrl {
  Ref ref;
  Signaling2Ctrl(this.ref);

  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      }
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;

  Future<bool> join() async {
    try {
      log('createPeerConnection | $configuration', name: 'signaling2');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // CANDIDATES
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
        var data = {
          "audience_id": ref.read(audienceProvider)!.id,
          "device_id": ref.read(deviceIdProvider),
          "candidate": candidate.toMap(),
        };
        await ref.read(signalingServiceProvider).addCandidate(CandidateType.audience, data);
        log('got candidate | ok', name: 'signaling2');
      };

      peerConnection!.onTrack = (RTCTrackEvent event) {
        event.streams[0].getTracks().forEach((track) {
          log('Add a track to the remoteStream $track', name: 'signaling2');
          remoteStream?.addTrack(track);
        });
      };

      // ANSWER
      final presenter = ref.read(selectedPresenterProvider);
      final offer = presenter!.offer;
      if (offer != null) {
        await peerConnection?.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );

        final answer = await peerConnection?.createAnswer();
        log('Create answer | ok', name: 'signaling2');

        peerConnection?.setLocalDescription(answer!);

        var data = {
          "device_id": ref.read(deviceIdProvider),
          "answer": answer!.toMap(),
        };
        await ref.read(audienceSvcProvider).upsert(data);
      }

      ref.listen(presenterCandidateProvider(presenter.deviceId), (previous, next) async {
        List<Map<String, dynamic>>? candidates = next.value;
        if (candidates != null && candidates.isNotEmpty) {
          log('Got new remote ICE candidate', name: 'signaling2');
          for (var row in candidates) {
            final candidate = row['candidate'];
            await peerConnection?.addCandidate(
              RTCIceCandidate(candidate['candidate'], candidate['sdpMid'], candidate['sdpMLineIndex']),
            );
          }
        }
      });

      return true;
    } catch (e) {
      log('createPeerConnection', error: e, name: 'signaling2');
      throw Exception(e.toString());
    }
  }

  Future close() async {
    try {
      await ref.read(signalingServiceProvider).removeCandidate(CandidateType.audience, ref.read(deviceIdProvider));
      await peerConnection?.close();
      peerConnection = null;
      await ref.read(remoteRendererProvider.notifier).state.dispose();
      log('close | ok', name: 'signaling2');
    } catch (e) {
      log('close', error: e, name: 'signaling2');
    }
  }

  Future openMedia() async {
    await ref.read(remoteRendererProvider.notifier).state.initialize();
    ref.read(remoteRendererProvider.notifier).state.srcObject = remoteStream;
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      log('ICE connection state change: $state', name: 'signaling2');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      log('ICE gathering state changed: $state', name: 'signaling2');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      log('Connection state change: $state', name: 'signaling2');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      log('Signaling state change: $state', name: 'signaling2');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      log("Add remote stream", name: 'signaling2');
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}

final signaling2CtrlProvider = Provider(Signaling2Ctrl.new);
