import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/session_model.dart';
import 'buttons.dart';
import 'chip_badge.dart';
import 'page_layout.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.onBook,
    required this.onWaitlist,
    this.isBooked = false,
    this.onWaitlistList = false,
    this.onViewBooking,
    this.isBusy = false,
  });
  final SessionModel session;
  final VoidCallback onBook, onWaitlist;
  final bool isBooked, onWaitlistList, isBusy;
  final VoidCallback? onViewBooking;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final elapsed =
        !session.startAt.isAfter(now) || session.status != 'scheduled';
    final level = session.level == 'all'
        ? 'All levels'
        : '${session.level[0].toUpperCase()}${session.level.substring(1)}';
    return FlexSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(session.startAt),
                      style: AppTextStyles.sessionTitle,
                    ),
                    Text(
                      '${session.endAt.difference(session.startAt).inMinutes} min',
                      style: AppTextStyles.chip.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title, style: AppTextStyles.sessionTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${session.coachName} · ${session.studioName}',
                      style: AppTextStyles.sessionMeta,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level,
                      style: AppTextStyles.chip.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${session.priceTnd.toStringAsFixed(0)} TND / session',
                style: AppTextStyles.priceTag,
              ),
              ChipBadge(
                text: isBooked
                    ? 'Reserved'
                    : elapsed
                    ? 'Closed'
                    : onWaitlistList
                    ? 'On waitlist'
                    : session.isFull
                    ? 'Full · waitlist available'
                    : '${session.placesLeft} places available',
                variant: isBooked
                    ? ChipBadgeVariant.green
                    : session.isFull
                    ? ChipBadgeVariant.amber
                    : ChipBadgeVariant.sage,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isBooked)
            FlexSecondaryButton(
              label: 'View reservation',
              onPressed: onViewBooking,
              icon: Icons.check_circle_outline_rounded,
            )
          else if (elapsed)
            const FlexSecondaryButton(
              label: 'Session unavailable',
              onPressed: null,
            )
          else if (onWaitlistList)
            FlexSecondaryButton(label: 'View waitlist', onPressed: onWaitlist)
          else if (session.isFull)
            FlexSecondaryButton(
              label: 'Join waitlist',
              onPressed: isBusy ? null : onWaitlist,
              icon: Icons.notifications_none_rounded,
            )
          else
            FlexPrimaryButton(
              label: 'Reserve a place',
              onPressed: isBusy ? null : onBook,
              icon: Icons.arrow_forward_rounded,
            ),
        ],
      ),
    );
  }
}
