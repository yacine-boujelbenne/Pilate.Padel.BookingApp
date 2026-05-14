import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class MemberProfileSummary {
  final int sessionsDone;
  final int sessionsLeft;
  final double ratingScore;
  final int monthsActive;
  final int pendingPayments;

  const MemberProfileSummary({
    required this.sessionsDone,
    required this.sessionsLeft,
    required this.ratingScore,
    required this.monthsActive,
    required this.pendingPayments,
  });

  String get paymentStatusLabel => pendingPayments > 0 ? 'Pending' : 'Good';
}

class MemberProfileSummaryService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<MemberProfileSummary> fetch({
    required String memberId,
    required DateTime createdAt,
    required String memberTier,
  }) async {
    final rows = await _client
        .from('bookings')
        .select('status, payment_status, sessions!inner(start_at, end_at)')
        .eq('member_id', memberId);

    final now = DateTime.now();
    var sessionsDone = 0;
    var sessionsLeft = 0;
    var pendingPayments = 0;

    for (final row in rows as List) {
      final booking = Map<String, dynamic>.from(row as Map);
      final status = (booking['status'] as String? ?? '').toLowerCase().trim();
      final paymentStatus =
          (booking['payment_status'] as String? ?? '').toLowerCase().trim();
      final session = booking['sessions'] as Map<String, dynamic>?;
      final startAt = _parseDate(session?['start_at']);
      final endAt = _parseDate(session?['end_at']);

      if (paymentStatus == 'pending') {
        pendingPayments++;
      }

      final isFutureBooking =
          startAt != null && !startAt.isBefore(now) && status == 'confirmed';
      final isPastBooking =
          (endAt != null && endAt.isBefore(now) && status != 'cancelled') ||
              status == 'attended';

      if (isFutureBooking) {
        sessionsLeft++;
      }
      if (isPastBooking) {
        sessionsDone++;
      }
    }

    return MemberProfileSummary(
      sessionsDone: sessionsDone,
      sessionsLeft: sessionsLeft,
      ratingScore: _ratingScoreForTier(memberTier),
      monthsActive: _monthsBetween(createdAt, now),
      pendingPayments: pendingPayments,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return null;
  }

  int _monthsBetween(DateTime from, DateTime to) {
    final months = (to.year - from.year) * 12 + to.month - from.month;
    return to.day < from.day ? months - 1 : months;
  }

  double _ratingScoreForTier(String memberTier) {
    switch (memberTier.toLowerCase().trim()) {
      case 'platinum':
        return 5.0;
      case 'gold':
        return 4.8;
      case 'silver':
        return 4.4;
      default:
        return 4.0;
    }
  }
}
