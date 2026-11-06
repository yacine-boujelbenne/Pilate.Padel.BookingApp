// Illustrative fixtures for tests and review captures only. Never imported by lib/.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_pilates_studio/controllers/auth_controller.dart';
import 'package:flex_pilates_studio/controllers/booking_controller.dart';
import 'package:flex_pilates_studio/controllers/session_controller.dart';
import 'package:flex_pilates_studio/controllers/waitlist_controller.dart';
import 'package:flex_pilates_studio/controllers/coach_controller.dart';
import 'package:flex_pilates_studio/controllers/admin_controller.dart';
import 'package:flex_pilates_studio/models/profile.dart';
import 'package:flex_pilates_studio/models/booking.dart';
import 'package:flex_pilates_studio/models/session_model.dart';
import 'package:flex_pilates_studio/models/waitlist_entry.dart';

SessionModel previewSession({bool full = false, DateTime? day}) {
  final today = day ?? DateTime.now().add(const Duration(days: 1));
  final start = DateTime(today.year, today.month, today.day, full ? 18 : 9);
  return SessionModel(
    id: full ? 'padel-session' : 'pilates-session',
    title: full ? 'Padel training' : 'Reformer flow',
    coachName: full ? 'Sam' : 'Amina',
    studioName: full ? 'Studio two' : 'Studio one',
    startAt: start,
    endAt: start.add(const Duration(hours: 1)),
    maxParticipants: 8,
    bookedCount: full ? 8 : 3,
    priceTnd: full ? 50 : 40,
    level: full ? 'intermediate' : 'all',
    status: 'scheduled',
  );
}

class PreviewAuth extends AuthController {
  PreviewAuth({this.role = 'member'});
  final String role;
  @override
  User? get user => User(
    id: 'preview-member',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01',
    email: 'alex@example.test',
  );
  @override
  Profile? get profile => Profile(
    id: 'preview-member',
    role: role,
    firstName: 'Alex',
    lastName: 'Morgan',
    createdAt: DateTime(2026),
  );
  @override
  bool get profileLoaded => true;
}

class PreviewSignedOut extends AuthController {
  @override
  bool get profileLoaded => true;
}

class PreviewSessions extends SessionController {
  DateTime _day = DateTime.now().add(const Duration(days: 1));
  @override
  List<SessionModel> get sessions => [
    previewSession(day: _day),
    previewSession(full: true, day: _day),
  ];
  @override
  Future<void> fetchSessionsByDate(DateTime date) async {
    _day = date;
    notifyListeners();
  }

  @override
  Future<void> fetchAllSessions() async {}
  @override
  Future<void> fetchPendingEditRequests() async {}
}

class PreviewBookings extends BookingController {
  @override
  List<Booking> get bookings => [
    Booking(
      id: 'preview-booking',
      memberId: 'preview-member',
      sessionId: 'reserved-session',
      paymentMethod: 'cash',
      paymentStatus: 'pending',
      paidAmountTnd: 40,
      bookedAt: DateTime(2026),
      status: 'confirmed',
      session: previewSession(),
    ),
  ];
  @override
  Future<void> fetchMemberBookings() async {}
  @override
  void subscribeRealtime() {}
}

class PreviewWaitlists extends WaitlistController {
  @override
  List<WaitlistEntry> get entries => [
    WaitlistEntry(
      id: 'preview-waitlist',
      memberId: 'preview-member',
      sessionId: 'padel-session',
      notifyChannel: 'push',
      position: 2,
      createdAt: DateTime(2026),
      session: previewSession(full: true),
    ),
  ];
  @override
  Future<void> fetchMemberWaitlists() async {}
  @override
  void subscribeRealtime() {}
}

Map<String, dynamic> staffSession() {
  final session = previewSession();
  return {
    'id': session.id,
    'title': session.title,
    'start_at': session.startAt.toIso8601String(),
    'end_at': session.endAt.toIso8601String(),
    'booked_count': 3,
    'max_participants': 8,
    'status': 'scheduled',
    'price_tnd': 40,
    'level': 'all',
  };
}

class PreviewCoach extends CoachController {
  @override
  List<Map<String, dynamic>> get schedule => [staffSession()];
  @override
  int get sessionsToday => 2;
  @override
  int get sessionsWeek => 8;
  @override
  int get upcomingSessions => 5;
  @override
  double get averageFillRate => .7;
  @override
  List<double> get fillRates => [.6, .75, .5, .9, .7];
  @override
  Future<void> fetchCoachSchedule() async {}
  @override
  Future<void> fetchCoachTrainees() async {}
  @override
  Future<void> fetchFillRateStats() async {}
}

class PreviewAdmin extends AdminController {
  @override
  Map<String, dynamic> get stats => {
    'activeMembers': 128,
    'sessionsWeek': 24,
    'revenueTnd': 3200.0,
    'activeCoaches': 6,
  };
  @override
  List<Map<String, dynamic>> get users => [
    {
      'id': 'preview-member',
      'first_name': 'Alex',
      'last_name': 'Morgan',
      'role': 'member',
      'member_tier': 'standard',
      'is_blocked': false,
    },
  ];
  @override
  List<Map<String, dynamic>> get coaches => [
    {
      'id': 'preview-coach',
      'first_name': 'Amina',
      'last_name': 'Test',
      'speciality': 'Pilates',
    },
  ];
  @override
  Future<void> refreshDashboardData() async {}
}
