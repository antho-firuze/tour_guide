import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CandidateType { presenter, audience }

class SignalingService {
  Ref ref;
  SignalingService(this.ref);

  Future addCandidate(CandidateType type, Object data) async {
    try {
      if (type == CandidateType.presenter) {
        await Supabase.instance.client.from('presenter_candidates').insert(data);
      }
      if (type == CandidateType.audience) {
        await Supabase.instance.client.from('audience_candidates').insert(data);
      }
      log('addCandidate | ok', name: 'signaling');
    } catch (e) {
      log('addCandidate | error | $e', name: 'signaling');
    }
  }

  Future removeCandidate(CandidateType type, String identifier) async {
    try {
      if (type == CandidateType.presenter) {
        await Supabase.instance.client.from('presenter_candidates').delete().eq('device_id', identifier);
      }
      if (type == CandidateType.audience) {
        await Supabase.instance.client.from('audience_candidates').delete().eq('device_id', identifier);
      }
      log('removeCandidate | ok', name: 'signaling');
    } catch (e) {
      log('removeCandidate | error | $e', name: 'signaling');
    }
  }
}

final signalingServiceProvider = Provider(SignalingService.new);
