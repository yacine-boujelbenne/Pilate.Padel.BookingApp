/// Enum for different types of notification events
enum NotificationEvent {
  COACH_SESSION_CREATED,
  SESSION_SPOT_AVAILABLE,
  WAITLIST_AVAILABLE,
  SESSION_CANCELLED,
  BOOKING_CONFIRMED,
  CUSTOM,
}

/// Enum for different notification channels
enum NotificationChannel { EMAIL, IN_APP, PUSH }

/// Data model for notifications
class NotificationData {
  final String id;
  final String memberId;
  final String? sessionId;
  final String title;
  final String body;
  final NotificationEvent eventType;
  final Map<String, dynamic> data;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isRead;

  const NotificationData({
    required this.id,
    required this.memberId,
    this.sessionId,
    required this.title,
    required this.body,
    required this.eventType,
    required this.data,
    this.deliveredAt,
    this.readAt,
    required this.createdAt,
    this.isRead = false,
  });

  /// Create a copy of this notification with modified fields
  NotificationData copyWith({
    String? id,
    String? memberId,
    String? sessionId,
    String? title,
    String? body,
    NotificationEvent? eventType,
    Map<String, dynamic>? data,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationData(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      body: body ?? this.body,
      eventType: eventType ?? this.eventType,
      data: data ?? this.data,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Convert to Map for Supabase operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'session_id': sessionId,
      'title': title,
      'body': body,
      'event_type': eventType.toString().split('.').last,
      'data': data,
      'delivered_at': deliveredAt?.toUtc().toIso8601String(),
      'read_at': readAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_read': isRead,
    };
  }

  /// Create from Supabase map
  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      id: map['id'] as String,
      memberId: map['member_id'] as String,
      sessionId: map['session_id'] as String?,
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      eventType: _parseEventType(map['event_type'] as String?),
      data: (map['data'] as Map<String, dynamic>?) ?? {},
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'] as String).toLocal()
          : null,
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      isRead: (map['is_read'] as bool?) ?? false,
    );
  }

  /// Parse event type from string
  static NotificationEvent _parseEventType(String? value) {
    switch (value?.toUpperCase()) {
      case 'COACH_SESSION_CREATED':
        return NotificationEvent.COACH_SESSION_CREATED;
      case 'SESSION_SPOT_AVAILABLE':
        return NotificationEvent.SESSION_SPOT_AVAILABLE;
      case 'WAITLIST_AVAILABLE':
        return NotificationEvent.WAITLIST_AVAILABLE;
      case 'SESSION_CANCELLED':
        return NotificationEvent.SESSION_CANCELLED;
      case 'BOOKING_CONFIRMED':
        return NotificationEvent.BOOKING_CONFIRMED;
      default:
        return NotificationEvent.CUSTOM;
    }
  }

  @override
  String toString() =>
      'NotificationData(id: $id, memberId: $memberId, title: $title, isRead: $isRead)';
}

/// User notification preferences
class NotificationPreferences {
  final String memberId;
  final List<NotificationChannel> enabledChannels;
  final List<NotificationEvent> enabledEventTypes;
  final DateTime updatedAt;

  const NotificationPreferences({
    required this.memberId,
    this.enabledChannels = const [
      NotificationChannel.EMAIL,
      NotificationChannel.IN_APP,
      NotificationChannel.PUSH,
    ],
    this.enabledEventTypes = const [
      NotificationEvent.COACH_SESSION_CREATED,
      NotificationEvent.SESSION_SPOT_AVAILABLE,
      NotificationEvent.WAITLIST_AVAILABLE,
      NotificationEvent.SESSION_CANCELLED,
      NotificationEvent.BOOKING_CONFIRMED,
    ],
    required this.updatedAt,
  });

  /// Check if email notifications are enabled
  bool get emailEnabled => enabledChannels.contains(NotificationChannel.EMAIL);
  
  /// Check if in-app notifications are enabled
  bool get inAppEnabled => enabledChannels.contains(NotificationChannel.IN_APP);
  
  /// Check if push notifications are enabled
  bool get pushEnabled => enabledChannels.contains(NotificationChannel.PUSH);

  /// Create a copy with modified fields
  NotificationPreferences copyWith({
    String? memberId,
    List<NotificationChannel>? enabledChannels,
    List<NotificationEvent>? enabledEventTypes,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      memberId: memberId ?? this.memberId,
      enabledChannels: enabledChannels ?? this.enabledChannels,
      enabledEventTypes: enabledEventTypes ?? this.enabledEventTypes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Map for Supabase operations
  Map<String, dynamic> toMap() {
    return {
      'member_id': memberId,
      'enabled_channels': enabledChannels
          .map((c) => c.toString().split('.').last)
          .toList(),
      'enabled_event_types': enabledEventTypes
          .map((e) => e.toString().split('.').last)
          .toList(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Create from Supabase map
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    final channels = (map['enabled_channels'] as List<dynamic>? ?? [])
        .map((c) => _parseChannel(c as String))
        .toList();

    final events = (map['enabled_event_types'] as List<dynamic>? ?? [])
        .map((e) => _parseEventType(e as String))
        .toList();

    return NotificationPreferences(
      memberId: map['member_id'] as String,
      enabledChannels: channels.isNotEmpty
          ? channels
          : const [
              NotificationChannel.EMAIL,
              NotificationChannel.IN_APP,
              NotificationChannel.PUSH,
            ],
      enabledEventTypes: events.isNotEmpty
          ? events
          : const [
              NotificationEvent.COACH_SESSION_CREATED,
              NotificationEvent.SESSION_SPOT_AVAILABLE,
              NotificationEvent.WAITLIST_AVAILABLE,
              NotificationEvent.SESSION_CANCELLED,
              NotificationEvent.BOOKING_CONFIRMED,
            ],
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }

  static NotificationChannel _parseChannel(String value) {
    switch (value.toUpperCase()) {
      case 'EMAIL':
        return NotificationChannel.EMAIL;
      case 'PUSH':
        return NotificationChannel.PUSH;
      case 'IN_APP':
        return NotificationChannel.IN_APP;
      default:
        return NotificationChannel.IN_APP;
    }
  }

  static NotificationEvent _parseEventType(String? value) {
    if (value == null) return NotificationEvent.CUSTOM;
    switch (value.toUpperCase()) {
      case 'COACH_SESSION_CREATED':
        return NotificationEvent.COACH_SESSION_CREATED;
      case 'SESSION_SPOT_AVAILABLE':
        return NotificationEvent.SESSION_SPOT_AVAILABLE;
      case 'WAITLIST_AVAILABLE':
        return NotificationEvent.WAITLIST_AVAILABLE;
      case 'SESSION_CANCELLED':
        return NotificationEvent.SESSION_CANCELLED;
      case 'BOOKING_CONFIRMED':
        return NotificationEvent.BOOKING_CONFIRMED;
      default:
        return NotificationEvent.CUSTOM;
    }
  }

  @override
  String toString() =>
      'NotificationPreferences(memberId: $memberId, channels: $enabledChannels, events: $enabledEventTypes)';
}
