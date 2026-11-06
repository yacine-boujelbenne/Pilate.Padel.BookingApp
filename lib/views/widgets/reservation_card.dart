import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/booking.dart';
import 'chip_badge.dart';
import 'page_layout.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.booking,
    this.featured = false,
    this.onTap,
    this.onCancel,
    this.busy = false,
  });
  final Booking booking;
  final bool featured, busy;
  final VoidCallback? onTap, onCancel;
  @override
  Widget build(BuildContext context) {
    final session = booking.session;
    final color = featured ? AppColors.white : AppColors.textDark;
    final muted = featured ? AppColors.mint : AppColors.textMid;
    final label = booking.statusLabelAt(DateTime.now());
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (featured) ...[
          Text(
            'YOUR NEXT SESSION',
            style: AppTextStyles.sectionLabel.copyWith(color: AppColors.mint),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          booking.displayTitle,
          style: AppTextStyles.sessionTitle.copyWith(
            color: color,
            fontSize: featured ? 22 : 17,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          session == null
              ? 'Session information is currently unavailable.'
              : '${DateFormat('EEE d MMM').format(session.startAt)} · ${DateFormat('HH:mm').format(session.startAt)}–${DateFormat('HH:mm').format(session.endAt)}',
          style: AppTextStyles.sessionMeta.copyWith(color: muted),
        ),
        if (session != null) ...[
          const SizedBox(height: 4),
          Text(
            '${session.coachName} · ${session.studioName}',
            style: AppTextStyles.sessionMeta.copyWith(color: muted),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChipBadge(
              text: label,
              variant: booking.isCancelled
                  ? ChipBadgeVariant.red
                  : ChipBadgeVariant.green,
            ),
            if (onTap != null)
              Text(
                'View reservation  →',
                style: AppTextStyles.chip.copyWith(color: color),
              ),
            if (onCancel != null)
              TextButton.icon(
                onPressed: busy ? null : onCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.redDark),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(busy ? 'Cancelling…' : 'Cancel reservation'),
              ),
          ],
        ),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: FlexSurface(
          color: featured ? AppColors.forest : AppColors.white,
          child: body,
        ),
      ),
    );
  }
}
