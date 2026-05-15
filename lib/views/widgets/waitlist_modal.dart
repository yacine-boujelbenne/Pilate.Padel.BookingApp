import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/locale_text.dart';
import 'buttons.dart';

class WaitlistModal extends StatefulWidget {
  final String sessionName;
  final int position;
  final ValueChanged<String> onJoin;

  const WaitlistModal({
    super.key,
    required this.sessionName,
    required this.position,
    required this.onJoin,
  });

  @override
  State<WaitlistModal> createState() => _WaitlistModalState();
}

class _WaitlistModalState extends State<WaitlistModal> {
  String _channel = 'push';

  @override
  Widget build(BuildContext context) {
    Widget option(String key, String label, IconData icon) {
      final selected = _channel == key;
      return InkWell(
        onTap: () => setState(() => _channel = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.mint : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.sageDark : AppColors.sagePale),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.sageDark),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.body),
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
          const SizedBox(height: 6),
          Text(
            context.t(
              "This session is full. Join the waitlist and we'll notify you the moment a spot opens.",
              "Cette séance est complète. Rejoignez la liste d’attente et nous vous avertirons dès qu’une place se libère.",
            ),
            style: AppTextStyles.sessionMeta.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.sageDark),
              alignment: Alignment.center,
              child: Text('#${widget.position}',
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          option('push', context.t('Push notification', 'Notification push'),
              Icons.notifications_active),
          const SizedBox(height: 8),
          option('sms', 'SMS', Icons.sms),
          const SizedBox(height: 8),
          option('email', 'Email', Icons.email),
          const SizedBox(height: 16),
          FlexPrimaryButton(
              label: context.t('Join waitlist & enable alerts',
                  'Rejoindre la liste d’attente et activer les alertes'),
              onPressed: () => widget.onJoin(_channel)),
        ],
      ),
    );
  }
}
