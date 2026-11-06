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
  int get placesLeft =>
      (maxParticipants - bookedCount).clamp(0, maxParticipants);
  bool canBookAt(DateTime now) =>
      status == 'scheduled' && startAt.isAfter(now) && !isFull;

  static const selection =
      '*, coach:profiles!coach_id(first_name, last_name), studio:studios(name)';

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    final coach = map['coach'] as Map<String, dynamic>?;
    final studio = map['studio'] as Map<String, dynamic>?;
    final coachLabel = coach == null
        ? ''
        : '${coach['first_name'] ?? ''} ${coach['last_name'] ?? ''}'.trim();
    return SessionModel(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? 'Session',
      coachName:
          (map['coach_name'] as String?) ??
          (coachLabel.isEmpty ? 'Coach to be confirmed' : coachLabel),
      studioName:
          (map['studio_name'] as String?) ??
          (studio?['name'] as String? ?? 'Studio to be confirmed'),
      startAt: DateTime.parse(map['start_at'] as String).toLocal(),
      endAt: DateTime.parse(map['end_at'] as String).toLocal(),
      maxParticipants: (map['max_participants'] as num?)?.toInt() ?? 10,
      bookedCount: (map['booked_count'] as num?)?.toInt() ?? 0,
      priceTnd: (map['price_tnd'] as num?)?.toDouble() ?? 0,
      level: (map['level'] as String?) ?? 'all',
      status: ((map['status'] as String?) ?? 'scheduled').toLowerCase().trim(),
    );
  }
}
