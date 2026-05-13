import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/session_model.dart';
import 'supabase_service.dart';

class CoachDirectoryEntry {
  final String id;
  final String firstName;
  final String lastName;
  final String? speciality;
  final String? avatarUrl;

  const CoachDirectoryEntry({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.speciality,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    final result = '$firstInitial$lastInitial'.trim();
    return result.isEmpty ? 'C' : result;
  }

  factory CoachDirectoryEntry.fromMap(Map<String, dynamic> map) {
    return CoachDirectoryEntry(
      id: map['id'] as String,
      firstName: (map['first_name'] as String?) ?? '',
      lastName: (map['last_name'] as String?) ?? '',
      speciality: map['speciality'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

class CoachDirectoryService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<CoachDirectoryEntry>> fetchVisibleCoaches() async {
    final res = await _client
        .from('profiles')
        .select('id, first_name, last_name, speciality, avatar_url')
        .eq('role', 'coach')
        .eq('is_blocked', false)
        .order('first_name');

    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(CoachDirectoryEntry.fromMap)
        .toList();
  }

  Future<CoachDirectoryCoachDetails?> fetchCoachDetails(String coachId) async {
    final res = await _client
        .from('profiles')
        .select('id, first_name, last_name, speciality, avatar_url, phone')
        .eq('id', coachId)
        .eq('role', 'coach')
        .eq('is_blocked', false)
        .maybeSingle();

    if (res == null) return null;
    return CoachDirectoryCoachDetails.fromMap(res);
  }

  Future<List<SessionModel>> fetchCoachRelatedSessions({
    required String coachId,
    required String coachName,
  }) async {
    final res = await _client
        .from('sessions')
        .select(
          'id, title, start_at, end_at, max_participants, booked_count, price_tnd, level, status, studios(name)',
        )
        .eq('coach_id', coachId)
        .order('start_at');

    return (res as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final studio = map['studios'] as Map<String, dynamic>?;
      return SessionModel.fromMap({
        ...map,
        'coach_name': coachName,
        'studio_name': (studio?['name'] as String?) ?? 'Studio',
      });
    }).toList();
  }
}

class CoachDirectoryCoachDetails {
  final String id;
  final String firstName;
  final String lastName;
  final String? speciality;
  final String? avatarUrl;
  final String? phone;

  const CoachDirectoryCoachDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.speciality,
    this.avatarUrl,
    this.phone,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory CoachDirectoryCoachDetails.fromMap(Map<String, dynamic> map) {
    return CoachDirectoryCoachDetails(
      id: map['id'] as String,
      firstName: (map['first_name'] as String?) ?? '',
      lastName: (map['last_name'] as String?) ?? '',
      speciality: map['speciality'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      phone: map['phone'] as String?,
    );
  }
}
