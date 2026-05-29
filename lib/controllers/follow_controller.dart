import 'package:flutter/material.dart';

import '../services/follow_service.dart';

class FollowController extends ChangeNotifier {
  final FollowService _service = FollowService();

  Set<String> _followedCoachIds = <String>{};
  Set<String> _followedSessionIds = <String>{};
  bool _loading = false;
  String? _error;

  Set<String> get followedCoachIds => _followedCoachIds;
  Set<String> get followedSessionIds => _followedSessionIds;
  bool get isLoading => _loading;
  String? get error => _error;
  int get followedCoachCount => _followedCoachIds.length;
  int get followedSessionCount => _followedSessionIds.length;

  Future<void> loadFollowState() async {
    _setLoading(true);
    try {
      final coachIds = await _service.fetchFollowedCoachIds();
      final sessionIds = await _service.fetchFollowedSessionIds();
      _followedCoachIds = coachIds;
      _followedSessionIds = sessionIds;
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  bool isCoachFollowed(String coachId) => _followedCoachIds.contains(coachId);

  bool isSessionFollowed(String sessionId) =>
      _followedSessionIds.contains(sessionId);

  Future<void> toggleCoachFollow(String coachId) async {
    final wasFollowed = isCoachFollowed(coachId);
    _setCoachFollowed(coachId, !wasFollowed);
    try {
      if (wasFollowed) {
        await _service.unfollowCoach(coachId);
      } else {
        await _service.followCoach(coachId);
      }
      _error = null;
      notifyListeners();
    } catch (error) {
      _setCoachFollowed(coachId, wasFollowed);
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleSessionFollow(String sessionId) async {
    final wasFollowed = isSessionFollowed(sessionId);
    _setSessionFollowed(sessionId, !wasFollowed);
    try {
      if (wasFollowed) {
        await _service.unfollowSession(sessionId);
      } else {
        await _service.followSession(sessionId);
      }
      _error = null;
      notifyListeners();
    } catch (error) {
      _setSessionFollowed(sessionId, wasFollowed);
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _setCoachFollowed(String coachId, bool followed) {
    final updated = Set<String>.from(_followedCoachIds);
    if (followed) {
      updated.add(coachId);
    } else {
      updated.remove(coachId);
    }
    _followedCoachIds = updated;
    notifyListeners();
  }

  void _setSessionFollowed(String sessionId, bool followed) {
    final updated = Set<String>.from(_followedSessionIds);
    if (followed) {
      updated.add(sessionId);
    } else {
      updated.remove(sessionId);
    }
    _followedSessionIds = updated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
