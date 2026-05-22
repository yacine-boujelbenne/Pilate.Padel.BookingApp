import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/session_model.dart';
import '../../l10n/locale_text.dart';
import 'buttons.dart';
import 'full_session_banner.dart';
import 'spots_bar.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onBook;
  final VoidCallback onWaitlist;
  final VoidCallback? onCancelBooking;
  final bool isBooked;
  final bool onWaitlistList;

  const SessionCard({
    super.key,
    required this.session,
    required this.onBook,
    required this.onWaitlist,
    this.onCancelBooking,
    this.isBooked = false,
    this.onWaitlistList = false,
  });

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final start = DateFormat('HH:mm').format(session.startAt);
    final end = DateFormat('HH:mm').format(session.endAt);

    return GlossCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                          DateFormat('EEE', localeTag)
                              .format(session.startAt)
                              .toUpperCase(),
                          style: AppTextStyles.chip
                              .copyWith(color: AppColors.sage)),
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
                          '$start - $end · ${context.tr('Coach')} ${session.coachName} · ${context.tr('Studio')} ${session.studioName}',
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
                          label: context.tr('Booked ✓'), onPressed: null)),
                  const SizedBox(width: 8),
                  _AnimatedCancelButton(onPressed: onCancelBooking),
                ],
              )
            else if (session.isFull)
              _AnimatedWaitlistButton(
                onWaitlistList: onWaitlistList,
                onPressed: onWaitlist,
              )
            else
              _AnimatedBookButton(onPressed: onBook),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBookButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedBookButton({required this.onPressed});

  @override
  State<_AnimatedBookButton> createState() => _AnimatedBookButtonState();
}

class _AnimatedBookButtonState extends State<_AnimatedBookButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovered
                ? AppColors.sage.withValues(alpha: 0.9)
                : AppColors.sageDark,
            elevation: _isHovered ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          child: Text(context.tr('Book'),
              style: AppTextStyles.buttonPrimary.copyWith(fontSize: 13)),
        ),
      ),
    );
  }
}

class _AnimatedWaitlistButton extends StatefulWidget {
  final bool onWaitlistList;
  final VoidCallback onPressed;

  const _AnimatedWaitlistButton({
    required this.onWaitlistList,
    required this.onPressed,
  });

  @override
  State<_AnimatedWaitlistButton> createState() =>
      _AnimatedWaitlistButtonState();
}

class _AnimatedWaitlistButtonState extends State<_AnimatedWaitlistButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: widget.onWaitlistList
                ? _isHovered
                    ? AppColors.mint
                    : AppColors.sagePale
                : _isHovered
                    ? AppColors.waitlistBorder.withValues(alpha: 0.3)
                    : AppColors.waitlistAmber,
            side: BorderSide(
              color: _isHovered ? AppColors.sage : AppColors.waitlistBorder,
              width: _isHovered ? 1.5 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          child: Text(
            widget.onWaitlistList
                ? context.tr('✓ On waitlist')
                : context.tr('🔔 Notify me'),
            style: AppTextStyles.buttonSecondary
                .copyWith(color: AppColors.amberDark, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCancelButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _AnimatedCancelButton({this.onPressed});

  @override
  State<_AnimatedCancelButton> createState() => _AnimatedCancelButtonState();
}

class _AnimatedCancelButtonState extends State<_AnimatedCancelButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isHovered ? AppColors.redDark : AppColors.redLight,
            foregroundColor:
                _isHovered ? AppColors.redLight : AppColors.redDark,
            elevation: _isHovered ? 3 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          child: Text(context.tr('Cancel')),
        ),
      ),
    );
  }
}
