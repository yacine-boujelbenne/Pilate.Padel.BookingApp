import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/follow_controller.dart';
import '../../app/theme.dart';
import '../../l10n/locale_text.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/modern_components.dart';
import '../widgets/modern_colors.dart';
import '../widgets/modern_theme.dart';

/// Screen showing all coaches followed by the member
/// Features: Search, filter by specialty, quick unfollow, modern design
class MyCoachesScreen extends StatefulWidget {
  const MyCoachesScreen({super.key});

  @override
  State<MyCoachesScreen> createState() => _MyCoachesScreenState();
}

class _MyCoachesScreenState extends State<MyCoachesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSpecialty = 'All';
  List<String> _specialties = ['All', 'Pilates', 'Yoga', 'Fitness'];
  List<Map<String, dynamic>> _filteredCoaches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }

  void _loadCoaches() async {
    try {
      final followController = context.read<FollowController>();
      final coaches = await followController.getMyFollowedCoachesWithDetails();
      
      setState(() {
        _filteredCoaches = coaches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _filterCoaches();
  }

  void _filterCoaches() {
    final followController = context.read<FollowController>();
    final query = _searchController.text.toLowerCase();

    context.read<FollowController>().getMyFollowedCoachesWithDetails().then((coaches) {
      setState(() {
        _filteredCoaches = coaches.where((coach) {
          final profile = coach['profiles'] as Map<String, dynamic>?;
          final firstName = profile?['first_name'] as String? ?? '';
          final lastName = profile?['last_name'] as String? ?? '';
          final specialty = profile?['speciality'] as String? ?? '';

          final matchesQuery =
              query.isEmpty ||
              firstName.toLowerCase().contains(query) ||
              lastName.toLowerCase().contains(query) ||
              specialty.toLowerCase().contains(query);

          final matchesSpecialty =
              _selectedSpecialty == 'All' ||
              specialty.toLowerCase() == _selectedSpecialty.toLowerCase();

          return matchesQuery && matchesSpecialty;
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.all(ModernSpacing.lg),
              decoration: BoxDecoration(
                gradient: ModernColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Coaches',
                        style: ModernTypography.headlineLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ModernSpacing.md),
                  Text(
                    'Coaches you follow',
                    style: ModernTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Search and Filter
            Padding(
              padding: const EdgeInsets.all(ModernSpacing.lg),
              child: Column(
                children: [
                  // Search field
                  ModernTextField(
                    controller: _searchController,
                    label: 'Search coaches',
                    hint: 'Name, specialty...',
                    prefixIcon: Icons.search,
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: ModernSpacing.md),

                  // Specialty filter
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _specialties.length,
                      itemBuilder: (context, index) {
                        final specialty = _specialties[index];
                        final isSelected = _selectedSpecialty == specialty;

                        return Padding(
                          padding: const EdgeInsets.only(right: ModernSpacing.md),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedSpecialty = specialty);
                              _filterCoaches();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ModernSpacing.lg,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? ModernColors.primaryGradient
                                    : null,
                                color: !isSelected
                                    ? Colors.grey[100]
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  ModernRadius.full,
                                ),
                                border: !isSelected
                                    ? Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  specialty,
                                  style: ModernTypography.labelMedium.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Coaches list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCoaches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 64,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              const SizedBox(height: ModernSpacing.lg),
                              Text(
                                'No coaches found',
                                style: ModernTypography.headlineSmall.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: ModernSpacing.md),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Start following coaches to see them here'
                                    : 'Try adjusting your search',
                                style: ModernTypography.bodyMedium.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(ModernSpacing.lg),
                          itemCount: _filteredCoaches.length,
                          itemBuilder: (context, index) {
                            return _buildCoachCard(_filteredCoaches[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachCard(Map<String, dynamic> coach) {
    final profile = coach['profiles'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? 'Unknown';
    final lastName = profile?['last_name'] as String? ?? '';
    final specialty = profile?['speciality'] as String? ?? 'Coach';
    final avatarUrl = profile?['avatar_url'] as String?;
    final coachId = profile?['id'] as String? ?? '';

    final fullName = '$firstName $lastName'.trim();
    final initials = '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ''}';

    return GestureDetector(
      onTap: () {
        // Navigate to coach detail
        Navigator.pushNamed(context, '/coach/$coachId');
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: ModernSpacing.lg),
        padding: const EdgeInsets.all(ModernSpacing.md),
        child: Row(
          children: [
            // Avatar
            if (avatarUrl != null && avatarUrl.isNotEmpty)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              AvatarWidget(initials: initials, size: 56),

            const SizedBox(width: ModernSpacing.md),

            // Coach info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: ModernTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: ModernSpacing.xs),
                  Text(
                    specialty,
                    style: ModernTypography.labelMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Unfollow button
            GestureDetector(
              onTap: () {
                _showUnfollowDialog(coachId, fullName);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnfollowDialog(String coachId, String coachName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.lg),
        ),
        title: const Text('Unfollow Coach?'),
        content: Text(
          'Are you sure you want to unfollow $coachName? You won\'t receive notifications about their sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unfollowCoach(coachId);
            },
            child: const Text(
              'Unfollow',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _unfollowCoach(String coachId) async {
    try {
      await context.read<FollowController>().unfollowCoach(coachId);
      _loadCoaches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coach unfollowed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
