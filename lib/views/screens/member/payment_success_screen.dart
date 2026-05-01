import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/success_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String sessionName;
  final double amount;
  final String method;

  const PaymentSuccessScreen({
    super.key,
    required this.sessionName,
    required this.amount,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return SuccessScreen(
      sessionName: sessionName,
      date: 'Upcoming session',
      coachStudio: 'Coach / Studio',
      method: method,
      amount: amount,
      onBackHome: () => context.go('/member/home'),
    );
  }
}
