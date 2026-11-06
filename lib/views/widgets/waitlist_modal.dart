import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'buttons.dart';
import 'page_layout.dart';

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
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => setState(() => _channel = key),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? AppColors.mint : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.sageDark : AppColors.sagePale,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.sageDark),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: AppTextStyles.body)),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.forest,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return FlexSheet(
      title: widget.sessionName,
      subtitle:
          'This session is full. Join the queue and choose your preferred notification channel.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your queue position is assigned when you join.',
            style: AppTextStyles.sessionMeta,
          ),
          const SizedBox(height: 16),
          option('push', 'Push notification', Icons.notifications_none_rounded),
          const SizedBox(height: 10),
          option('sms', 'SMS', Icons.sms_outlined),
          const SizedBox(height: 10),
          option('email', 'Email', Icons.mail_outline_rounded),
          const SizedBox(height: 20),
          FlexPrimaryButton(
            label: 'Join waitlist',
            onPressed: () => widget.onJoin(_channel),
          ),
        ],
      ),
    );
  }
}
