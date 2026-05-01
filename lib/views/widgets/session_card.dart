import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/session_model.dart';
import 'buttons.dart';
import 'full_session_banner.dart';
import 'spots_bar.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onBook;
  final VoidCallback onWaitlist;
  final bool isBooked;
  final bool onWaitlistList;

  const SessionCard({
    super.key,
    required this.session,
    required this.onBook,
    required this.onWaitlist,
    this.isBooked = false,
    this.onWaitlistList = false,
  });

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('HH:mm').format(session.startAt);
    final end = DateFormat('HH:mm').format(session.endAt);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        DateFormat('EEE').format(session.startAt).toUpperCase(),
                        style:
                            AppTextStyles.chip.copyWith(color: AppColors.sage)),
                    Text(DateFormat('d').format(session.startAt),
                        style: AppTextStyles.screenTitle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.sageDark)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title,
                        style: AppTextStyles.sessionTitle,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                        '$start - $end · Coach ${session.coachName} · Studio ${session.studioName}',
                        style: AppTextStyles.sessionMeta),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.sagePale),
                      ),
                      child: Text(
                          '${session.priceTnd.toStringAsFixed(0)} TND / session',
                          style: AppTextStyles.priceTag),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SpotsBar(booked: session.bookedCount, max: session.maxParticipants),
          if (session.isFull) ...[
            const SizedBox(height: 8),
            const FullSessionBanner(),
          ],
          const SizedBox(height: 10),
          if (isBooked)
            Row(
              children: [
                Expanded(
                    child: FlexSecondaryButton(
                        label: 'Booked ✓', onPressed: null)),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redLight,
                    foregroundColor: AppColors.redDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            )
          else if (session.isFull)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onWaitlist,
                style: OutlinedButton.styleFrom(
                  backgroundColor: onWaitlistList
                      ? AppColors.sagePale
                      : AppColors.waitlistAmber,
                  side: const BorderSide(color: AppColors.waitlistBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                ),
                child: Text(
                  onWaitlistList ? '✓ On waitlist' : '🔔 Notify me',
                  style: AppTextStyles.buttonSecondary
                      .copyWith(color: AppColors.amberDark, fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                ),
                child: Text('Book',
                    style: AppTextStyles.buttonPrimary.copyWith(fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}
