import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/follow_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../../models/session_model.dart';
import '../../../services/coach_directory_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/booking_modal.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/payment_modal.dart';
import '../../widgets/toast_message.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowController>().loadFollowState();
    });
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
          _error = context.tr('Coach not found');
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

  Future<void> _openBookingFlow(SessionModel session) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingModal(
        session: session,
        onConfirm: () {
          Navigator.of(context).pop();
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PaymentModal(
              sessionName: session.title,
              amount: session.priceTnd,
              onPay: (method) async {
                Navigator.of(context).pop();
                try {
                  await context.read<BookingController>().bookSession(
                        sessionId: session.id,
                        paymentMethod: method,
                        amount: session.priceTnd,
                      );
                  if (!mounted) return;
                  context.go('/member/payment-success', extra: {
                    'sessionName': session.title,
                    'amount': session.priceTnd,
                    'method': method,
                  });
                } catch (_) {
                  if (mounted) {
                    ToastMessage.show(
                        context,
                        context.tr(
                            'Could not complete booking. Please try again.'));
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coach = _coach;
    final now = DateTime.now();

    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Coach Details',
        showBack: true,
        backTarget: '/member/explore',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || coach == null
              ? Center(
                  child: Text(
                    _error ?? context.tr('Could not load coach details'),
                    style: AppTextStyles.body,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
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
                              size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coach.fullName,
                                  style: AppTextStyles.body
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  coach.speciality?.trim().isNotEmpty == true
                                      ? coach.speciality!
                                      : context.tr('Coach'),
                                  style: AppTextStyles.sessionMeta,
                                ),
                              ],
                            ),
                          ),
                          ChipBadge(
                              text: context.tr('Active'),
                              variant: ChipBadgeVariant.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<FollowController>(
                      builder: (context, follows, _) {
                        final isFollowed =
                            follows.isCoachFollowed(widget.coachId);
                        return SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: follows.isLoading
                                ? null
                                : () async {
                                    try {
                                      await context
                                          .read<FollowController>()
                                          .toggleCoachFollow(widget.coachId);
                                    } catch (_) {
                                      if (mounted) {
                                        ToastMessage.show(
                                            context,
                                            context.t(
                                                'Could not update follow status. Please try again.',
                                                'Impossible de mettre à jour le suivi. Veuillez réessayer.'));
                                      }
                                    }
                                  },
                            icon: Icon(
                              isFollowed
                                  ? Icons.notifications_active
                                  : Icons.notifications_none,
                            ),
                            label: Text(
                              isFollowed
                                  ? context.tr('Watching coach')
                                  : context.tr('Follow coach'),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(context.tr('CONTACT INFO'),
                        style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        coach.phone?.trim().isNotEmpty == true
                            ? '${context.tr('Phone:')} ${coach.phone}'
                            : context.tr('Phone: not provided'),
                        style: AppTextStyles.body,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(context.tr('RELATED SESSIONS'),
                        style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),
                    if (_sessions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          context.tr(
                              'No scheduled sessions found for this coach.'),
                          style: AppTextStyles.body,
                        ),
                      )
                    else
                      ..._sessions.map((session) {
                        final isUpcoming = session.startAt.isAfter(now) ||
                            session.startAt.isAtSameMomentAs(now);
                        final dateLabel = DateFormat('EEE d MMM · HH:mm')
                            .format(session.startAt);

                        return InkWell(
                          onTap: isUpcoming
                              ? () => _openBookingFlow(session)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.title,
                                        style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateLabel,
                                        style: AppTextStyles.sessionMeta,
                                      ),
                                      Text(
                                        '${session.priceTnd.toStringAsFixed(0)} TND',
                                        style: AppTextStyles.sessionMeta,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ChipBadge(
                                      text: isUpcoming
                                          ? context.tr('Book')
                                          : context.tr('Closed'),
                                      variant: isUpcoming
                                          ? ChipBadgeVariant.green
                                          : ChipBadgeVariant.red,
                                    ),
                                    const SizedBox(height: 6),
                                    Consumer<FollowController>(
                                      builder: (context, follows, _) {
                                        final isFollowed = follows
                                            .isSessionFollowed(session.id);
                                        return TextButton.icon(
                                          onPressed: follows.isLoading
                                              ? null
                                              : () async {
                                                  try {
                                                    await context
                                                        .read<
                                                            FollowController>()
                                                        .toggleSessionFollow(
                                                            session.id);
                                                  } catch (_) {
                                                    if (mounted) {
                                                      ToastMessage.show(
                                                          context,
                                                          context.t(
                                                              'Could not update follow status. Please try again.',
                                                              'Impossible de mettre à jour le suivi. Veuillez réessayer.'));
                                                    }
                                                  }
                                                },
                                          icon: Icon(
                                            isFollowed
                                                ? Icons.notifications_active
                                                : Icons.notifications_none,
                                            size: 18,
                                          ),
                                          label: Text(
                                            isFollowed
                                                ? context.tr('Watching')
                                                : context.tr('Follow'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}
