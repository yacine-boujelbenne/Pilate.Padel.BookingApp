import '../../widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/booking_controller.dart';
import '../../../models/session_model.dart';
import '../../../services/coach_directory_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/booking_flow.dart';
import '../../widgets/session_card.dart';
import '../../widgets/waitlist_flow.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';

class MemberCoachDetailScreen extends StatefulWidget {
  final String coachId;

  const MemberCoachDetailScreen({super.key, required this.coachId});

  @override
  State<MemberCoachDetailScreen> createState() =>
      _MemberCoachDetailScreenState();
}

class _MemberCoachDetailScreenState extends State<MemberCoachDetailScreen> {
  final CoachDirectoryService _service = CoachDirectoryService();
  CoachDirectoryCoachDetails? _coach;
  List<SessionModel> _sessions = [];
  bool _loading = true;
  bool _waiting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final coach = await _service.fetchCoachDetails(widget.coachId);
      if (coach == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Coach not found';
          _loading = false;
        });
        return;
      }

      final sessions = await _service.fetchCoachRelatedSessions(
        coachId: widget.coachId,
        coachName: coach.fullName,
      );

      if (!mounted) return;
      setState(() {
        _coach = coach;
        _sessions = sessions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = _coach;

    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Coach Details',
        showBack: true,
        backTarget: '/member/explore',
      ),
      body: FlexPage(
        maxWidth: 1120,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null || coach == null
            ? FlexErrorCard(
                message: 'This coach could not be loaded.',
                onRetry: _load,
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        AvatarWidget(
                          initials: coach.fullName.isNotEmpty
                              ? coach.fullName[0]
                              : 'C',
                          size: 56,
                          imageUrl: coach.avatarUrl,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coach.fullName,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                coach.speciality?.trim().isNotEmpty == true
                                    ? coach.speciality!
                                    : 'Coach',
                                style: AppTextStyles.sessionMeta,
                              ),
                            ],
                          ),
                        ),
                        const ChipBadge(
                          text: 'Active',
                          variant: ChipBadgeVariant.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('CONTACT INFO', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      coach.phone?.trim().isNotEmpty == true
                          ? 'Phone: ${coach.phone}'
                          : 'Phone: not provided',
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('RELATED SESSIONS', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 6),
                  if (_sessions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'No scheduled sessions found for this coach.',
                        style: AppTextStyles.body,
                      ),
                    )
                  else
                    ..._sessions.map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SessionCard(
                          session: session,
                          isBooked: context
                              .watch<BookingController>()
                              .bookings
                              .any(
                                (b) =>
                                    b.sessionId == session.id &&
                                    b.status == 'confirmed',
                              ),
                          isBusy:
                              _waiting ||
                              context.watch<BookingController>().isSubmitting,
                          onViewBooking: () => context.go('/member/bookings'),
                          onBook: () => openSessionBooking(context, session),
                          onWaitlist: () async {
                            if (_waiting) return;
                            setState(() => _waiting = true);
                            try {
                              await openSessionWaitlist(context, session);
                            } finally {
                              if (mounted) {
                                setState(() => _waiting = false);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
