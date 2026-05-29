import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class FollowNotificationService {
  FollowNotificationService._();

  static final FollowNotificationService instance =
      FollowNotificationService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  Future<void> notifyCoachSessionAssigned({
    required String sessionId,
    required String coachId,
  }) async {
    await _invokeSafely({
      'event_type': 'coach_session_assigned',
      'session_id': sessionId,
      'coach_id': coachId,
    });
  }

  Future<void> notifySessionUpdated({
    required String sessionId,
  }) async {
    await _invokeSafely({
      'event_type': 'session_updated',
      'session_id': sessionId,
    });
  }

  Future<void> notifySessionSpotOpened({
    required String sessionId,
    String? bookingId,
  }) async {
    final payload = <String, dynamic>{
      'event_type': 'session_spot_opened',
      'session_id': sessionId,
    };

    if (bookingId != null && bookingId.isNotEmpty) {
      payload['booking_id'] = bookingId;
    }

    await _invokeSafely(payload);
  }

  Future<void> notifySessionCancelled({
    required String sessionId,
  }) async {
    await _invokeSafely({
      'event_type': 'session_cancelled',
      'session_id': sessionId,
    });
  }

  Future<void> _invokeSafely(Map<String, dynamic> payload) async {
    try {
      await _client.functions.invoke(
        'send-push-notification',
        body: payload,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to dispatch follow notification: $error');
      }
    }
  }
}
