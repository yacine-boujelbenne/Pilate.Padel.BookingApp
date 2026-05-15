import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/locale_text.dart';
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
              Text(context.tr('Booking confirmed!'),
                  style: AppTextStyles.logoTitle
                      .copyWith(fontSize: 26, color: AppColors.sageDark)),
              const SizedBox(height: 6),
              Text(
                isCash
                    ? context.t(
                        'Your spot is reserved. Please bring ${amount.toStringAsFixed(0)} TND to the studio.',
                        'Votre place est réservée. Merci d’apporter ${amount.toStringAsFixed(0)} TND au studio.')
                    : context.t(
                        'Payment of ${amount.toStringAsFixed(0)} TND confirmed. See you on the mat!',
                        'Paiement de ${amount.toStringAsFixed(0)} TND confirmé. À bientôt sur le tapis !'),
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
                    Text('${context.tr('Payment:')} $method',
                        style: AppTextStyles.body),
                    Text(
                        '${context.tr('Total paid:')} ${amount.toStringAsFixed(0)} TND',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Spacer(),
              FlexSecondaryButton(
                  label: context.tr('Back to home'), onPressed: onBackHome),
            ],
          ),
        ),
      ),
    );
  }
}
