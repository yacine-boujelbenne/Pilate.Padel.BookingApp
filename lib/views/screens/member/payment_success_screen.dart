import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/session_model.dart';

import '../../widgets/success_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String sessionName;
  final double amount;
  final String method;
  final SessionModel? session;

  const PaymentSuccessScreen({
    super.key,
    required this.sessionName,
    required this.amount,
    required this.method,
    this.session,
  });

  @override
  Widget build(BuildContext context) {
    return SuccessScreen(
      sessionName: sessionName,
      date: session == null
          ? 'View your reservation in My Bookings'
          : DateFormat('EEE d MMM · HH:mm').format(session!.startAt),
      coachStudio: session == null
          ? ''
          : '${session!.coachName} · ${session!.studioName}',
      method: method,
      amount: amount,
      onBackHome: () => context.go('/member/home'),
      onViewBookings: () => context.go('/member/bookings'),
    );
  }
}
