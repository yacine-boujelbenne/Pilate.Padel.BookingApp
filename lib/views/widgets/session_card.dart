import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/session_model.dart';
import 'buttons.dart';
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
    final start = session.startAt.toLocal();
    final duration = session.endAt.difference(session.startAt).inMinutes;
    final expired = !session.startAt.isAfter(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('HH:mm').format(start),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$duration min · ${session.level == 'all' ? 'All levels' : session.level}',
                  style: AppTextStyles.sessionMeta,
                ),
              ),
              if (isBooked)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.greenDark,
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            session.title,
            style: AppTextStyles.modalTitle.copyWith(fontSize: 23),
          ),
          const SizedBox(height: 8),
          Text(
            '${session.coachName} · ${session.studioName}',
            style: AppTextStyles.sessionMeta,
          ),
          const SizedBox(height: 20),
          SpotsBar(booked: session.bookedCount, max: session.maxParticipants),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.priceTnd.toStringAsFixed(2)} TND',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('per person', style: AppTextStyles.sessionMeta),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: isBooked
                    ? FlexSecondaryButton(label: 'Reserved', onPressed: null)
                    : expired
                        ? FlexSecondaryButton(label: 'Started', onPressed: null)
                        : session.isFull
                            ? FlexSecondaryButton(
                                label: onWaitlistList
                                    ? 'On waitlist'
                                    : 'Join waitlist',
                                onPressed: onWaitlistList ? null : onWaitlist,
                              )
                            : FlexPrimaryButton(
                                label: 'Book session',
                                onPressed: onBook,
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
