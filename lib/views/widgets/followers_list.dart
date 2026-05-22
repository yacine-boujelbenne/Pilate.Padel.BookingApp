import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/follow_controller.dart';
import '../../models/profile.dart';
import 'avatar_widget.dart';
import 'chip_badge.dart';
import 'modern_components.dart';
import 'modern_colors.dart';
import 'modern_theme.dart';

/// Modal widget displaying list of followers for a coach
/// Features: Avatar, name, tier level, scrollable list, empty state
class FollowersListModal extends StatefulWidget {
  final String coachId;
  final String coachName;

  const FollowersListModal({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  State<FollowersListModal> createState() => _FollowersListModalState();
}

class _FollowersListModalState extends State<FollowersListModal> {
  late Future<List<Map<String, dynamic>>> _followersFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  void _loadFollowers() {
    final followController = context.read<FollowController>();
    _followersFuture = followController.getCoachFollowers(widget.coachId, limit: 100);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ModernRadius.xl),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ModernRadius.xl),
          boxShadow: ModernShadows.highElevation,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(ModernSpacing.lg),
              decoration: BoxDecoration(
                gradient: ModernColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(ModernRadius.xl),
                  topRight: Radius.circular(ModernRadius.xl),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Followers",
                          style: ModernTypography.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: ModernSpacing.xs),
                        Text(
                          widget.coachName,
                          style: ModernTypography.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _followersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.withOpacity(0.5),
                          ),
                          const SizedBox(height: ModernSpacing.md),
                          Text(
                            "Failed to load followers",
                            style: ModernTypography.bodyMedium.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final followers = snapshot.data ?? [];

                  if (followers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(height: ModernSpacing.md),
                          Text(
                            "No followers yet",
                            style: ModernTypography.bodyMedium.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(ModernSpacing.md),
                    itemCount: followers.length,
                    itemBuilder: (context, index) {
                      return _buildFollowerItem(followers[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowerItem(Map<String, dynamic> follower) {
    final profile = follower['profiles'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? 'Unknown';
    final lastName = profile?['last_name'] as String? ?? '';
    final avatarUrl = profile?['avatar_url'] as String?;
    final tier = profile?['member_tier'] as String? ?? 'standard';

    final fullName = '$firstName $lastName'.trim();
    final initials = '${firstName.isNotEmpty ? firstName[0] : 'U'}${lastName.isNotEmpty ? lastName[0] : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: ModernSpacing.md),
      padding: const EdgeInsets.all(ModernSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(ModernRadius.lg),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          if (avatarUrl != null && avatarUrl.isNotEmpty)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(avatarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            AvatarWidget(
              initials: initials,
              size: 48,
            ),

          const SizedBox(width: ModernSpacing.md),

          // Name and tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: ModernTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: ModernSpacing.xs),
                ChipBadge(
                  label: tier.replaceFirst(tier[0], tier[0].toUpperCase()),
                  color: _getTierColor(tier),
                  size: ChipBadgeSize.small,
                ),
              ],
            ),
          ),

          // Message button
          GestureDetector(
            onTap: () {
              // TODO: Navigate to chat/message screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message $firstName (Coming soon)'),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: ModernColors.secondaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.message_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return Colors.amber;
      case 'gold':
        return Colors.orange;
      case 'silver':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
