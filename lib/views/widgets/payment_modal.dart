import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'buttons.dart';

class PaymentModal extends StatefulWidget {
  final String sessionName;
  final double amount;
  final ValueChanged<String> onPay;

  const PaymentModal({
    super.key,
    required this.sessionName,
    required this.amount,
    required this.onPay,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String _method = 'cash';

  @override
  Widget build(BuildContext context) {
    Widget tile(String key, String title, String subtitle, IconData icon) {
      final selected = _method == key;
      return InkWell(
        onTap: () => setState(() => _method = key),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.mint : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.sageDark : AppColors.sagePale,
                width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.sageDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: AppTextStyles.sessionMeta),
                  ],
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color:
                          selected ? AppColors.sageDark : AppColors.sagePale),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.sageDark),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.sessionName, style: AppTextStyles.modalTitle),
          const SizedBox(height: 4),
          Text('Total ${widget.amount.toStringAsFixed(0)} TND',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          tile('cash', 'Cash at studio', 'Pay at the studio on the day',
              Icons.payments),
          const SizedBox(height: 8),
          tile('card', 'Bank card', 'Visa / Mastercard', Icons.credit_card),
          const SizedBox(height: 8),
          tile('mobile', 'Mobile wallet', 'D17 / Flouci / ...',
              Icons.phone_android),
          const SizedBox(height: 16),
          FlexPrimaryButton(
            label: _method == 'cash'
                ? 'Reserve - Pay at studio'
                : 'Pay ${widget.amount.toStringAsFixed(0)} TND',
            onPressed: () => widget.onPay(_method),
          ),
        ],
      ),
    );
  }
}
