import 'session_model.dart';

class WaitlistEntry {
  final String id;
  final String memberId;
  final String sessionId;
  final String notifyChannel;
  final int position;
  final DateTime createdAt;
  final SessionModel? session;

  const WaitlistEntry({
    required this.id,
    required this.memberId,
    required this.sessionId,
    required this.notifyChannel,
    required this.position,
    required this.createdAt,
    this.session,
  });

  factory WaitlistEntry.fromMap(Map<String, dynamic> map) {
    return WaitlistEntry(
      id: map['id'] as String,
      memberId: map['member_id'] as String,
      sessionId: map['session_id'] as String,
      notifyChannel: (map['notify_channel'] as String?) ?? 'push',
      position: (map['position'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      session: map['session'] is Map<String, dynamic>
          ? SessionModel.fromMap(map['session'] as Map<String, dynamic>)
          : null,
    );
  }
}
