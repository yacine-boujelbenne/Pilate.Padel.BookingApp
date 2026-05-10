class BookingDetail {
  final String bookingId;
  final String memberId;
  final String memberName;
  final String memberEmail;
  final String paymentMethod;
  final String paymentStatus;
  final double paidAmountTnd;
  final DateTime bookedAt;
  final String status;

  const BookingDetail({
    required this.bookingId,
    required this.memberId,
    required this.memberName,
    required this.memberEmail,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAmountTnd,
    required this.bookedAt,
    required this.status,
  });

  factory BookingDetail.fromMap(Map<String, dynamic> map) {
    return BookingDetail(
      bookingId: map['id'] as String,
      memberId: map['member_id'] as String,
      memberName: (map['member_name'] as String?) ?? 'Unknown',
      memberEmail: (map['member_email'] as String?) ?? '',
      paymentMethod: (map['payment_method'] as String?) ?? 'cash',
      paymentStatus: (map['payment_status'] as String?) ?? 'pending',
      paidAmountTnd: (map['paid_amount_tnd'] as num?)?.toDouble() ?? 0,
      bookedAt: DateTime.parse(map['booked_at'] as String),
      status: (map['status'] as String?) ?? 'confirmed',
    );
  }
}
