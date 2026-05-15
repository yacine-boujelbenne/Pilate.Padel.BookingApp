import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/member_profile_summary_service.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/stat_card.dart';

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  static final MemberProfileSummaryService _summaryService =
      MemberProfileSummaryService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    final summaryFuture = profile == null
        ? null
        : _summaryService.fetch(
            memberId: profile.id,
            createdAt: profile.createdAt,
            memberTier: profile.memberTier,
          );

    return Scaffold(
      appBar: const FlexAppBar(title: 'Profile', badgeText: 'Member'),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) context.go('/member/home');
          if (index == 1) context.go('/member/explore');
          if (index == 2) context.go('/member/bookings');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'EXPLORE'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'MY BOOKINGS'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: AvatarWidget(
              initials: profile?.firstName.isNotEmpty == true
                  ? profile!.firstName[0]
                  : 'M',
              size: 72,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              profile?.fullName ?? 'Member',
              style: AppTextStyles.modalTitle
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child:
                Text(auth.user?.email ?? '', style: AppTextStyles.sessionMeta),
          ),
          const SizedBox(height: 6),
          Center(
            child: ChipBadge(
              text:
                  '${_capitalize(profile?.memberTier ?? 'standard')} ${context.t('Member', 'Membre')}',
              variant: ChipBadgeVariant.green,
            ),
          ),
          const SizedBox(height: 14),
          if (profile == null)
            const Center(child: CircularProgressIndicator())
          else
            FutureBuilder<MemberProfileSummary>(
              future: summaryFuture,
              builder: (context, snapshot) {
                final summary = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting &&
                    summary == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      value: '${summary?.sessionsDone ?? 0}',
                      label: context.t('Sessions done', 'Séances effectuées'),
                    ),
                    StatCard(
                      value: '${summary?.sessionsLeft ?? 0}',
                      label: context.t('Sessions left', 'Séances restantes'),
                    ),
                    StatCard(
                      value: (summary?.ratingScore ?? 0).toStringAsFixed(1),
                      label: context.t('Avg rating', 'Note moyenne'),
                    ),
                    StatCard(
                      value: '${summary?.monthsActive ?? 0}',
                      label: context.t('Months active', 'Mois actif'),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          FlexPrimaryButton(
            label: context.t('Manage account', 'Gérer le compte'),
            onPressed: () => context.go('/account/manage'),
          ),
          const SizedBox(height: 8),
          FlexSecondaryButton(
            label: context.t('Settings', 'Paramètres'),
            onPressed: () => context.go('/settings', extra: '/member/profile'),
          ),
          const SizedBox(height: 8),
          FlexSecondaryButton(
            label: context.t('Sign out', 'Se déconnecter'),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }
}
