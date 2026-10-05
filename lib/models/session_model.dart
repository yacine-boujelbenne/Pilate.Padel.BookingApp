class SessionModel {
  final String id;
  final String title;
  final String coachName;
  final String studioName;
  final DateTime startAt;
  final DateTime endAt;
  final int maxParticipants;
  final int bookedCount;
  final double priceTnd;
  final String level;
  final String status;

  const SessionModel({
    required this.id,
    required this.title,
    required this.coachName,
    required this.studioName,
    required this.startAt,
    required this.endAt,
    required this.maxParticipants,
    required this.bookedCount,
    required this.priceTnd,
    required this.level,
    required this.status,
  });

  bool get isFull => bookedCount >= maxParticipants;

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    final coach = map['profiles'] as Map<String, dynamic>?;
    final studio = map['studios'] as Map<String, dynamic>?;
    final coachName = [
      coach?['first_name'],
      coach?['last_name'],
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return SessionModel(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? 'Session',
      coachName: (map['coach_name'] as String?) ??
          (coachName.isEmpty ? 'Coach to be announced' : coachName),
      studioName: (map['studio_name'] as String?) ??
          studio?['name'] as String? ??
          'Studio to be announced',
      startAt: DateTime.parse(map['start_at'] as String),
      endAt: DateTime.parse(map['end_at'] as String),
      maxParticipants: (map['max_participants'] as num?)?.toInt() ?? 10,
      bookedCount: (map['booked_count'] as num?)?.toInt() ?? 0,
      priceTnd: (map['price_tnd'] as num?)?.toDouble() ?? 0,
      level: (map['level'] as String?) ?? 'all',
      status: (map['status'] as String?) ?? 'scheduled',
    );
  }
}
