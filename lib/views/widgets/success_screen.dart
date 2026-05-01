import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'buttons.dart';

class SuccessScreen extends StatelessWidget {
  final String sessionName;
  final String date;
  final String coachStudio;
  final String method;
  final double amount;
  final VoidCallback onBackHome;

  const SuccessScreen({
    super.key,
    required this.sessionName,
    required this.date,
    required this.coachStudio,
    required this.method,
    required this.amount,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    final isCash = method == 'cash';
    return Scaffold(
      backgroundColor: AppColors.mint,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.check_circle,
                  size: 72, color: AppColors.greenDark),
              const SizedBox(height: 12),
              Text('Booking confirmed!',
                  style: AppTextStyles.logoTitle
                      .copyWith(fontSize: 26, color: AppColors.sageDark)),
              const SizedBox(height: 6),
              Text(
                isCash
                    ? 'Your spot is reserved. Please bring ${amount.toStringAsFixed(0)} TND to the studio.'
                    : 'Payment of ${amount.toStringAsFixed(0)} TND confirmed. See you on the mat!',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessionName,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(date, style: AppTextStyles.sessionMeta),
                    Text(coachStudio, style: AppTextStyles.sessionMeta),
                    const SizedBox(height: 6),
                    Text('Payment: $method', style: AppTextStyles.body),
                    Text('Total paid: ${amount.toStringAsFixed(0)} TND',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Spacer(),
              FlexSecondaryButton(label: 'Back to home', onPressed: onBackHome),
            ],
          ),
        ),
      ),
    );
  }
}
