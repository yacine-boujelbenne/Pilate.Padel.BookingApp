import 'session_model.dart';

class Booking {
  final String id;
  final String memberId;
  final String sessionId;
  final String paymentMethod;
  final String paymentStatus;
  final double paidAmountTnd;
  final DateTime bookedAt;
  final DateTime? cancelledAt;
  final String status;
  final SessionModel? session;

  const Booking({
    required this.id,
    required this.memberId,
    required this.sessionId,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAmountTnd,
    required this.bookedAt,
    required this.status,
    this.cancelledAt,
    this.session,
  });

  bool get isCancelled =>
      status == 'cancelled' || session?.status == 'cancelled';
  bool isUpcomingAt(DateTime now) =>
      !isCancelled &&
      status == 'confirmed' &&
      session != null &&
      session!.status == 'scheduled' &&
      session!.startAt.isAfter(now);
  String get displayTitle => session?.title ?? 'Session details unavailable';
  String statusLabelAt(DateTime now) {
    if (isCancelled) return 'Cancelled';
    if (status == 'attended') return 'Attended';
    if (session == null) return 'Confirmed';
    if (session!.endAt.isBefore(now) || session!.status == 'completed') {
      return 'Completed';
    }
    if (!session!.startAt.isAfter(now)) return 'In progress';
    return 'Upcoming';
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      memberId: map['member_id'] as String,
      sessionId: map['session_id'] as String,
      paymentMethod: (map['payment_method'] as String?) ?? 'cash',
      paymentStatus: (map['payment_status'] as String?) ?? 'pending',
      paidAmountTnd: (map['paid_amount_tnd'] as num?)?.toDouble() ?? 0,
      bookedAt: DateTime.parse(map['booked_at'] as String),
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.parse(map['cancelled_at'] as String)
          : null,
      status: ((map['status'] as String?) ?? 'confirmed').toLowerCase().trim(),
      session: map['session'] is Map<String, dynamic>
          ? SessionModel.fromMap(map['session'] as Map<String, dynamic>)
          : null,
    );
  }
}
