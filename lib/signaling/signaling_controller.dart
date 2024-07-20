import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/model/audience.dart';
import 'package:tour_guide/presenter/presenter_controller.dart';
import 'package:tour_guide/presenter/presenter_service.dart';
import 'package:tour_guide/signaling/signaling_service.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

final localRendererProvider = StateProvider<RTCVideoRenderer>((ref) => RTCVideoRenderer());

class SignalingCtrl {
  Ref ref;
  SignalingCtrl(this.ref);

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

  Future<bool> create() async {
    try {
      log('createPeerConnection | $configuration', name: 'signaling');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // CANDIDATES
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
        var data = {
          "presenter_id": ref.read(presenterProvider)!.id,
          "device_id": ref.read(deviceIdProvider),
          "candidate": candidate.toMap(),
        };
        await ref.read(signalingServiceProvider).addCandidate(CandidateType.presenter, data);
        log('got candidate | ok', name: 'signaling');
      };

      // OFFER
      RTCSessionDescription offer = await peerConnection!.createOffer();
      var data = {
        "device_id": ref.read(deviceIdProvider),
        "offer": offer.toMap(),
      };
      await ref.read(presenterSvcProvider).upsert(data);
      log('Created offer | ok', name: 'signaling');

      await peerConnection?.setLocalDescription(offer);

      peerConnection!.onTrack = (RTCTrackEvent event) {
        event.streams[0].getTracks().forEach((track) {
          log('Add a track to the remoteStream $track', name: 'signaling');
          remoteStream?.addTrack(track);
        });
      };

      ref.listen(liveAudienceProvider(ref.watch(presenterProvider)!.id!), (previous, next) async {
        List<Audience>? audiences = next.value;
        if (audiences != null && audiences.isNotEmpty) {
          // log('Count Audience | ${audiences.length}', name: 'signaling');
          for (var audience in audiences) {
            // log('Got Audience | ${audience.deviceId}', name: 'signaling');
            if (await peerConnection?.getRemoteDescription() != null && audience.answer != null) {
              var answer = RTCSessionDescription(audience.answer!['sdp'], audience.answer!['type']);
              log('Got Audience | ${audience.deviceId}', name: 'signaling');
              await peerConnection?.setRemoteDescription(answer);
            }

            ref.listen(audienceCandidateProvider(audience.deviceId), (previous, next) async {
              log('Got new remote ICE candidate', name: 'signaling');
              List<Map<String, dynamic>>? candidates = next.value;
              if (candidates != null && candidates.isNotEmpty) {
                for (var row in candidates) {
                  final candidate = row['candidate'];
                  await peerConnection?.addCandidate(
                    RTCIceCandidate(candidate['candidate'], candidate['sdpMid'], candidate['sdpMLineIndex']),
                  );
                }
              }
            });
          }
        } else {
          log('Hangout Audience', name: 'signaling');
        }
      });

      return true;
    } catch (e) {
      log('createPeerConnection', error: e, name: 'signaling');
      throw Exception(e.toString());
    }
  }

  Future close() async {
    try {
      await ref.read(signalingServiceProvider).removeCandidate(CandidateType.presenter, ref.read(deviceIdProvider));
      await peerConnection?.close();
      peerConnection = null;
      await ref.read(localRendererProvider.notifier).state.dispose();
      log('close | ok', name: 'signaling');
    } catch (e) {
      log('close', error: e, name: 'signaling');
    }
  }

  Future openMedia() async {
    await ref.read(localRendererProvider.notifier).state.initialize();
    var stream = await navigator.mediaDevices.getUserMedia({'video': false, 'audio': true});
    ref.read(localRendererProvider.notifier).state.srcObject = stream;
    localStream = stream;
  }

  Future join() async {}

  Future unjoin() async {
    try {
      await ref.read(signalingServiceProvider).removeCandidate(CandidateType.audience, ref.read(deviceIdProvider));
      await peerConnection?.close();
      peerConnection = null;
      log('close | ok', name: 'signaling');
    } catch (e) {
      log('close', error: e, name: 'signaling');
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

    peerConnection?.onAddStream = (MediaStream stream) {
      log("Add remote stream", name: 'signaling');
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}

final signalingCtrlProvider = Provider(SignalingCtrl.new);
