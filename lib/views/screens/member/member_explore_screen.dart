import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../services/coach_directory_service.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/coach_card.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/form_fields.dart';

class MemberExploreScreen extends StatefulWidget {
  const MemberExploreScreen({super.key});

  @override
  State<MemberExploreScreen> createState() => _MemberExploreScreenState();
}

class _MemberExploreScreenState extends State<MemberExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CoachDirectoryService _coachDirectoryService = CoachDirectoryService();
  final List<CoachDirectoryEntry> _allCoaches = [];
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _loadCoaches();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadCoaches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final coaches = await _coachDirectoryService.fetchVisibleCoaches();
      if (!mounted) return;
      setState(() {
        _allCoaches
          ..clear()
          ..addAll(coaches);
      });
      debugPrint('Loaded ${coaches.length} coaches');
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
    final coaches = _allCoaches.where((coach) {
      if (_searchQuery.isEmpty) {
        return true;
      }

      final haystack = [
        coach.firstName,
        coach.lastName,
        coach.speciality,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: const FlexAppBar(title: 'Explore', badgeText: 'Member'),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/member/home');
          if (index == 2) context.go('/member/bookings');
          if (index == 3) context.go('/member/profile');
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
          FlexFormInput(
              controller: _searchController,
              hint: 'Search sessions or coaches…'),
          const SizedBox(height: 12),
          Text('OUR COACHES', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          if (_loading && coaches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Could not load coaches right now.',
                style: AppTextStyles.body,
              ),
            )
          else if (coaches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _searchQuery.isEmpty
                    ? 'No coaches available yet.'
                    : 'No coaches match your search.',
                style: AppTextStyles.body,
              ),
            )
          else
            ...coaches.map(
              (coach) {
                final specialty = coach.speciality?.trim().isNotEmpty == true
                    ? coach.speciality!
                    : 'Coach';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Expanded(
                        child: CoachCard(
                          name: coach.fullName,
                          speciality: specialty,
                          onTap: () =>
                              context.go('/member/coaches/${coach.id}'),
                        ),
                      ),
                      const ChipBadge(
                          text: 'Active', variant: ChipBadgeVariant.green),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
