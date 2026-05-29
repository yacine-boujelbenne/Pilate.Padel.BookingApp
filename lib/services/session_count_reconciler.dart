import 'package:supabase_flutter/supabase_flutter.dart';

class SessionCountReconciler {
  const SessionCountReconciler._();

  static Future<List<Map<String, dynamic>>> reconcile(
    SupabaseClient client,
    List<dynamic> rows,
  ) async {
    final sessions = rows
        .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
        .toList();

    if (sessions.isEmpty) {
      return sessions;
    }

    final sessionIds = sessions
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .where((sessionId) => sessionId.isNotEmpty)
        .toList();

    if (sessionIds.isEmpty) {
      return sessions;
    }

    final bookingRows = await client
        .from('bookings')
        .select('session_id')
        .eq('status', 'confirmed')
        .inFilter('session_id', sessionIds);

    final confirmedCounts = <String, int>{};
    for (final row in bookingRows as List) {
      final booking = row as Map<String, dynamic>;
      final sessionId = booking['session_id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        continue;
      }
      confirmedCounts[sessionId] = (confirmedCounts[sessionId] ?? 0) + 1;
    }

    for (final session in sessions) {
      final sessionId = session['id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        continue;
      }

      final actualBooked = confirmedCounts[sessionId] ?? 0;
      final currentBooked = (session['booked_count'] as num?)?.toInt() ?? 0;
      if (currentBooked == actualBooked) {
        continue;
      }

      session['booked_count'] = actualBooked;
      await client.from('sessions').update({
        'booked_count': actualBooked,
      }).eq('id', sessionId);
    }

    return sessions;
  }
}
