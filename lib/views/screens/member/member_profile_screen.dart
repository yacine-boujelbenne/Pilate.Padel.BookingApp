import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/member_profile_summary_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/stat_card.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key});
  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final _service = MemberProfileSummaryService();
  Future<MemberProfileSummary>? _summary;
  String? _profileKey;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.watch<AuthController>().profile;
    final key = profile == null
        ? null
        : '${profile.id}:${profile.memberTier}:${profile.createdAt}';
    if (key != _profileKey) {
      _profileKey = key;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final profile = context.read<AuthController>().profile;
    if (profile == null) return;
    final future = _service.fetch(
      memberId: profile.id,
      createdAt: profile.createdAt,
      memberTier: profile.memberTier,
    );
    setState(() => _summary = future);
    try {
      await future;
    } catch (_) {
      /* Presented by FutureBuilder with retry. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    final name = profile?.fullName.trim() ?? '';
    return Scaffold(
      appBar: const FlexAppBar(title: 'Your space'),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 3,
        onTap: (i) => goToMemberTab(context, i),
        items: memberDestinations,
      ),
      body: FlexPage(
        maxWidth: 760,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              FlexEntrance(
                child: FlexSurface(
                  child: Column(
                    children: [
                      AvatarWidget(
                        initials: name.isEmpty ? 'M' : name[0],
                        imageUrl: profile?.avatarUrl,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name.isEmpty ? 'Your profile' : name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.modalTitle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        auth.user?.email ?? '',
                        style: AppTextStyles.sessionMeta,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ChipBadge(
                        text: '${profile?.memberTier ?? 'standard'} member',
                        variant: ChipBadgeVariant.sage,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const FlexSectionHeader(title: 'Your movement, so far'),
              FutureBuilder<MemberProfileSummary>(
                future: _summary,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const FlexLoading();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return FlexErrorCard(
                      message: 'Your activity couldn’t be loaded.',
                      onRetry: _refresh,
                    );
                  }
                  final value = snapshot.data!;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 580 ? 3 : 2;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 12) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final item in [
                            (value.sessionsDone, 'Sessions completed'),
                            (value.sessionsLeft, 'Upcoming sessions'),
                            (value.monthsActive, 'Months with Fléx'),
                          ])
                            SizedBox(
                              width: width,
                              child: StatCard(
                                value: '${item.$1}',
                                label: item.$2,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 28),
              const FlexSectionHeader(title: 'Make it yours'),
              FlexPrimaryButton(
                label: 'Manage account',
                onPressed: () => context.go('/account/manage'),
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 10),
              FlexSecondaryButton(
                label: 'My waitlists',
                onPressed: () => context.push('/member/waitlists'),
                icon: Icons.notifications_none_rounded,
              ),
              const SizedBox(height: 10),
              FlexSecondaryButton(
                label: 'Club updates',
                onPressed: () => context.push('/member/notifications'),
                icon: Icons.inbox_outlined,
              ),
              const SizedBox(height: 10),
              FlexSecondaryButton(
                label: 'Settings',
                onPressed: () =>
                    context.go('/settings', extra: '/member/profile'),
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
