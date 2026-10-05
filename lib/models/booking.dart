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
  final double? quotedAmountTnd;

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
    this.quotedAmountTnd,
  });

  double get amountDueTnd =>
      ((quotedAmountTnd ?? session?.priceTnd ?? 0) - paidAmountTnd)
          .clamp(0, double.infinity)
          .toDouble();
  bool get isUpcoming =>
      status == 'confirmed' &&
      session != null &&
      session!.status == 'scheduled' &&
      session!.startAt.isAfter(DateTime.now());

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
      status: (map['status'] as String?) ?? 'confirmed',
      quotedAmountTnd: (map['quoted_amount_tnd'] as num?)?.toDouble(),
      session: map['sessions'] is Map
          ? SessionModel.fromMap(
              Map<String, dynamic>.from(map['sessions'] as Map),
            )
          : null,
    );
  }
}
