import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../services/follow_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/flex_app_bar.dart';

class MemberFollowingScreen extends StatefulWidget {
  const MemberFollowingScreen({super.key});

  @override
  State<MemberFollowingScreen> createState() => _MemberFollowingScreenState();
}

class _MemberFollowingScreenState extends State<MemberFollowingScreen> {
  final FollowService _service = FollowService();
  List<FollowedCoachSummary> _coaches = [];
  List<FollowedSessionSummary> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetchFollowedCoaches(),
        _service.fetchFollowedSessions(),
      ]);
      if (!mounted) return;
      setState(() {
        _coaches = results[0] as List<FollowedCoachSummary>;
        _sessions = results[1] as List<FollowedSessionSummary>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _unfollowCoach(String coachId) async {
    await _service.unfollowCoach(coachId);
    await _load();
  }

  Future<void> _unfollowSession(String sessionId) async {
    await _service.unfollowSession(sessionId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM · HH:mm');

    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Following',
        showBack: true,
        backTarget: '/member/profile',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Followed coaches', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 8),
                  if (_coaches.isEmpty)
                    _emptyState('You are not following any coaches yet.')
                  else
                    ..._coaches.map((coach) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
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
                                size: 44,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(coach.fullName,
                                        style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      coach.speciality?.trim().isNotEmpty ==
                                              true
                                          ? coach.speciality!
                                          : 'Coach',
                                      style: AppTextStyles.sessionMeta,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _unfollowCoach(coach.coachId),
                                child: const Text('Unfollow'),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 12),
                  Text('Followed sessions', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 8),
                  if (_sessions.isEmpty)
                    _emptyState('You are not following any sessions yet.')
                  else
                    ..._sessions.map((session) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: session.isFull
                                      ? AppColors.waitlistAmber
                                      : AppColors.mint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  session.isFull
                                      ? Icons.notifications_active
                                      : Icons.event_available,
                                  color: AppColors.sageDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(session.title,
                                        style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${dateFormat.format(session.startAt)} · ${session.coachName}',
                                      style: AppTextStyles.sessionMeta,
                                    ),
                                    Text(
                                      '${session.bookedCount}/${session.maxParticipants} · ${session.studioName}',
                                      style: AppTextStyles.chip,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _unfollowSession(session.sessionId),
                                child: const Text('Unfollow'),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: AppTextStyles.body),
    );
  }
}
