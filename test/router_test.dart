import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_pilates_studio/app/router.dart';
import 'package:flex_pilates_studio/app/theme.dart';
import 'package:flex_pilates_studio/controllers/auth_controller.dart';
import 'package:flex_pilates_studio/controllers/session_controller.dart';
import 'package:flex_pilates_studio/controllers/booking_controller.dart';
import 'package:flex_pilates_studio/controllers/waitlist_controller.dart';
import 'package:flex_pilates_studio/controllers/coach_controller.dart';
import 'package:flex_pilates_studio/controllers/admin_controller.dart';
import 'support/preview_controllers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, dynamic>{} : true,
        );
    await Supabase.initialize(
      url: 'https://example.invalid',
      anonKey: 'test-public-client-key',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      debug: false,
    );
  });
  tearDownAll(() async => Supabase.instance.dispose());
  for (final role in ['member', 'coach', 'admin', 'signed-out']) {
    testWidgets('$role retains protected-route behavior', (tester) async {
      final auth = role == 'signed-out'
          ? PreviewSignedOut()
          : PreviewAuth(role: role);
      final router = AppRouter(auth).router;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: auth),
            ChangeNotifierProvider<SessionController>(
              create: (_) => PreviewSessions(),
            ),
            ChangeNotifierProvider<BookingController>(
              create: (_) => PreviewBookings(),
            ),
            ChangeNotifierProvider<WaitlistController>(
              create: (_) => PreviewWaitlists(),
            ),
            ChangeNotifierProvider<CoachController>(
              create: (_) => PreviewCoach(),
            ),
            ChangeNotifierProvider<AdminController>(
              create: (_) => PreviewAdmin(),
            ),
          ],
          child: MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: router,
          ),
        ),
      );
      router.go(role == 'admin' ? '/coach/home' : '/admin/home');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        role == 'signed-out' ? '/login' : '/$role/home',
      );
      if (role == 'member') {
        router.go('/sessions/example/attendees');
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/member/home');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      auth.dispose();
    });
  }
}
