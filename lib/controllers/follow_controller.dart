import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// State management controller for coach following functionality using Provider pattern
/// Manages follow relationships between members and coaches with Supabase integration
class FollowController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  // State variables
  Set<String> _followedCoachIds = {};
  Map<String, int> _coachFollowerCounts = {};
  Map<String, List<Map<String, dynamic>>> _coachFollowers = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Getters
  Set<String> get followedCoachIds => _followedCoachIds;
  Map<String, int> get coachFollowerCounts => _coachFollowerCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize controller for current user
  Future<void> initialize(String userId) async {
    try {
      _currentUserId = userId;
      _setLoading(true);

      // Load user's followed coaches
      await fetchMyFollowedCoaches();

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all coaches followed by current user
  Future<void> fetchMyFollowedCoaches() async {
    if (_currentUserId == null) return;

    try {
      _setLoading(true);

      final response = await _client
          .from('coach_follows')
          .select('coach_id')
          .eq('member_id', _currentUserId!);

      _followedCoachIds = Set.from(
        (response as List).map((row) => row['coach_id'] as String),
      );

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Follow a coach
  Future<void> followCoach(String coachId) async {
    if (_currentUserId == null) return;

    try {
      _setLoading(true);

      // Add follow record to database
      await _client.from('coach_follows').insert({
        'member_id': _currentUserId!,
        'coach_id': coachId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update local state
      _followedCoachIds.add(coachId);

      // Update follower count
      await _updateFollowerCount(coachId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Unfollow a coach
  Future<void> unfollowCoach(String coachId) async {
    if (_currentUserId == null) return;

    try {
      _setLoading(true);

      // Remove follow record from database
      await _client
          .from('coach_follows')
          .delete()
          .eq('member_id', _currentUserId!)
          .eq('coach_id', coachId);

      // Update local state
      _followedCoachIds.remove(coachId);

      // Update follower count
      await _updateFollowerCount(coachId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if currently following a coach
  bool isCoachFollowed(String coachId) {
    return _followedCoachIds.contains(coachId);
  }

  /// Toggle follow status for a coach
  Future<void> toggleFollowStatus(String coachId) async {
    if (isCoachFollowed(coachId)) {
      await unfollowCoach(coachId);
    } else {
      await followCoach(coachId);
    }
  }

  /// Get list of followers for a coach
  Future<List<Map<String, dynamic>>> getCoachFollowers(
    String coachId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _setLoading(true);

      final response = await _client
          .from('coach_follows')
          .select(
            'member_id, created_at, profiles!member_id(id, first_name, last_name, avatar_url, member_tier)',
          )
          .eq('coach_id', coachId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      _coachFollowers[coachId] = List<Map<String, dynamic>>.from(
        response as List,
      );

      _error = null;
      return _coachFollowers[coachId] ?? [];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get follower count for a coach
  Future<int> getFollowerCount(String coachId) async {
    try {
      final response = await _client
          .from('coach_follows')
          .select()
          .eq('coach_id', coachId)
          .count(CountOption.exact);

      final count = response.count ?? 0;
      _coachFollowerCounts[coachId] = count;
      notifyListeners();

      return count;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Get cached follower count for a coach
  int getFollowerCountCached(String coachId) {
    return _coachFollowerCounts[coachId] ?? 0;
  }

  /// Get top followers for a coach (limited list)
  Future<List<Map<String, dynamic>>> getTopCoachFollowers(
    String coachId, {
    int limit = 5,
  }) async {
    try {
      final response = await _client
          .from('coach_follows')
          .select(
            'member_id, created_at, profiles!member_id(id, first_name, last_name, avatar_url, member_tier)',
          )
          .eq('coach_id', coachId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Search coaches followed by current user
  Future<List<Map<String, dynamic>>> searchFollowedCoaches(String query) async {
    if (_currentUserId == null) return [];

    try {
      final searchTerm = '%$query%';

      final response = await _client
          .from('coach_follows')
          .select(
            'coach_id, profiles!coach_id(id, first_name, last_name, avatar_url, speciality)',
          )
          .eq('member_id', _currentUserId!)
          .or(
            'profiles.first_name.ilike.$searchTerm,profiles.last_name.ilike.$searchTerm,profiles.speciality.ilike.$searchTerm',
          );

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get coaches followed by current user with full details
  Future<List<Map<String, dynamic>>> getMyFollowedCoachesWithDetails({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_currentUserId == null) return [];

    try {
      _setLoading(true);

      final response = await _client
          .from('coach_follows')
          .select(
            'coach_id, created_at, profiles!coach_id(id, first_name, last_name, avatar_url, speciality, role)',
          )
          .eq('member_id', _currentUserId!)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      _error = null;
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Filter followed coaches by specialty
  Future<List<Map<String, dynamic>>> filterFollowedCoachesBySpecialty(
    String specialty,
  ) async {
    if (_currentUserId == null) return [];

    try {
      final response = await _client
          .from('coach_follows')
          .select(
            'coach_id, created_at, profiles!coach_id(id, first_name, last_name, avatar_url, speciality)',
          )
          .eq('member_id', _currentUserId!)
          .eq('profiles.speciality', specialty)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Check if current user is following a coach
  Future<bool> checkFollowStatus(String coachId) async {
    if (_currentUserId == null) return false;

    try {
      final response = await _client
          .from('coach_follows')
          .select('id')
          .eq('member_id', _currentUserId!)
          .eq('coach_id', coachId)
          .single();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Private helper to update follower count for a coach
  Future<void> _updateFollowerCount(String coachId) async {
    try {
      final count = await getFollowerCount(coachId);
      _coachFollowerCounts[coachId] = count;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  /// Clear controller state
  @override
  void dispose() {
    _followedCoachIds.clear();
    _coachFollowerCounts.clear();
    _coachFollowers.clear();
    _isLoading = false;
    _error = null;
    _currentUserId = null;
    super.dispose();
  }
}
