import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../models/booking_detail.dart';
import '../services/follow_notification_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class BookingController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  List<Booking> _bookings = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  List<BookingDetail> _sessionBookings = [];

  List<Booking> get bookings => _bookings;
  bool get isLoading => _loading;
  String? get error => _error;
  List<BookingDetail> get sessionBookings => _sessionBookings;

  void subscribeRealtime() {
    _channel ??= _client.channel('bookings-live')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        callback: (_) => fetchMemberBookings(),
      )
      ..subscribe();
  }

  Future<void> bookSession({
    required String sessionId,
    required String paymentMethod,
    required double amount,
  }) async {
    _setLoading(true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      final existing = await _client
          .from('bookings')
          .select('id, status')
          .eq('member_id', uid)
          .eq('session_id', sessionId);

      // Check for existing confirmed bookings with case-insensitive status
      final hasConfirmed = (existing as List).any((e) =>
          (e as Map<String, dynamic>)['status']
              .toString()
              .toLowerCase()
              .trim() ==
          'confirmed');

      if (hasConfirmed) {
        throw Exception("You're already booked!");
      }

      final inserted = await _client
          .from('bookings')
          .insert({
            'member_id': uid,
            'session_id': sessionId,
            'payment_method': paymentMethod,
            'payment_status': paymentMethod == 'cash' ? 'pending' : 'paid',
            'paid_amount_tnd': amount,
            'status': 'confirmed',
          })
          .select()
          .single();

      final createdBooking = Booking.fromMap(
        Map<String, dynamic>.from(inserted as Map),
      );
      _bookings = [
        createdBooking,
        ..._bookings.where((booking) => booking.id != createdBooking.id),
      ];
      notifyListeners();

      await _adjustSessionBookedCount(sessionId, 1);

      _error = null;
      await _syncSessionRemindersForUser();
      await fetchMemberBookings();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    _setLoading(true);
    try {
      final bookingRow = await _client
          .from('bookings')
          .select('session_id, status')
          .eq('id', bookingId)
          .maybeSingle();

      final bookingStatus = bookingRow?['status']?.toString().toLowerCase().trim();
      final sessionId = bookingRow?['session_id']?.toString();

      if (bookingStatus == 'cancelled') {
        _error = null;
        await fetchMemberBookings();
        return;
      }

      await _client.from('bookings').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      if (sessionId != null && sessionId.isNotEmpty) {
        await _adjustSessionBookedCount(sessionId, -1);
        await FollowNotificationService.instance.notifySessionSpotOpened(
          sessionId: sessionId,
          bookingId: bookingId,
        );
        await NotificationService.instance.cancelSessionReminders(sessionId);
      }

      _error = null;
      await _syncSessionRemindersForUser();
      await fetchMemberBookings();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchMemberBookings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      _bookings = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final res = await _client
          .from('bookings')
          .select()
          .eq('member_id', uid)
          .order('booked_at', ascending: false);
      _bookings = (res as List)
          .map((e) => Booking.fromMap(e as Map<String, dynamic>))
          .toList();
      _error = null;
      await _syncSessionRemindersForUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSessionBookings(String sessionId) async {
    _setLoading(true);
    try {
      final res =
          await _client.from('bookings').select().eq('session_id', sessionId);
      _bookings = (res as List)
          .map((e) => Booking.fromMap(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSessionBookingsWithMembers(String sessionId) async {
    _setLoading(true);
    try {
      final res = await _client
          .from('bookings')
          .select(
            '*, profiles!member_id(first_name, last_name, phone, role)',
          )
          .eq('session_id', sessionId)
          .eq('status', 'confirmed')
          .order('booked_at', ascending: false);

      // Filter for confirmed status with case-insensitive comparison
      _sessionBookings = (res as List)
          .where((e) =>
              (e as Map<String, dynamic>)['status']
                  .toString()
                  .toLowerCase()
                  .trim() ==
              'confirmed')
          .map((e) {
        final booking = e as Map<String, dynamic>;
        final profile = booking['profiles'] as Map<String, dynamic>?;
        return BookingDetail(
          bookingId: booking['id'] as String,
          memberId: booking['member_id'] as String,
          memberName:
              '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'
                  .trim(),
          memberEmail: profile?['phone'] as String? ?? '',
          paymentMethod: booking['payment_method'] as String? ?? 'cash',
          paymentStatus: booking['payment_status'] as String? ?? 'pending',
          paidAmountTnd: (booking['paid_amount_tnd'] as num?)?.toDouble() ?? 0,
          bookedAt: DateTime.parse(booking['booked_at'] as String),
          status: booking['status'] as String? ?? 'confirmed',
        );
      }).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> validatePayment(String bookingId) async {
    await _client
        .from('bookings')
        .update({'payment_status': 'paid'}).eq('id', bookingId);
    await fetchMemberBookings();
  }

  Future<void> _syncSessionRemindersForUser() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return;
    }

    bool remindersEnabled = true;
    try {
      final settings = await _client
          .from('user_settings')
          .select('reminders_enabled')
          .eq('user_id', uid)
          .maybeSingle();
      remindersEnabled = (settings?['reminders_enabled'] as bool?) ?? true;
    } catch (e) {
      final message = e.toString().toLowerCase();
      final missingUserSettingsTable =
          message.contains('public.user_settings') &&
              (message.contains('pgrst205') ||
                  message.contains('does not exist') ||
                  message.contains('schema cache'));
      if (!missingUserSettingsTable) {
        rethrow;
      }
    }

    if (!remindersEnabled) {
      await NotificationService.instance.cancelAllSessionReminders();
      return;
    }

    final confirmedBookings = _bookings.where((booking) => booking.status == 'confirmed').toList();
    if (confirmedBookings.isEmpty) {
      return;
    }

    final sessionIds = confirmedBookings.map((booking) => booking.sessionId).toSet().toList();
    final sessionRows = await _client
        .from('sessions')
        .select('id, title, start_at, end_at, profiles!coach_id(first_name, last_name), studios(name)')
        .inFilter('id', sessionIds);

    final sessionsById = <String, Map<String, dynamic>>{
      for (final row in (sessionRows as List))
        (row as Map<String, dynamic>)['id'].toString(): row,
    };

    for (final booking in confirmedBookings) {
      final session = sessionsById[booking.sessionId];
      if (session == null) {
        continue;
      }

      final coach = (session['profiles'] as Map<String, dynamic>?) ?? const {};
      final studio = (session['studios'] as Map<String, dynamic>?) ?? const {};
      final coachName = '${coach['first_name'] ?? ''} ${coach['last_name'] ?? ''}'.trim();
      final studioName = (studio['name'] as String?) ?? 'Studio';
      final startAt = DateTime.parse(session['start_at'] as String);
      await NotificationService.instance.scheduleSessionReminders(
        sessionId: booking.sessionId,
        title: (session['title'] as String?) ?? 'Session',
        startAt: startAt,
        coachName: coachName.isEmpty ? 'Coach' : coachName,
        studioName: studioName,
      );
    }
  }

  Future<void> _adjustSessionBookedCount(String sessionId, int delta) async {
    if (delta == 0) {
      return;
    }

    final sessionRow = await _client
        .from('sessions')
        .select('booked_count')
        .eq('id', sessionId)
        .maybeSingle();

    if (sessionRow == null) {
      return;
    }

    final currentBooked = (sessionRow['booked_count'] as num?)?.toInt() ?? 0;
    final nextBooked = (currentBooked + delta).clamp(0, 1 << 30);

    await _client.from('sessions').update({
      'booked_count': nextBooked,
    }).eq('id', sessionId);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
