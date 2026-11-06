import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_pilates_studio/app/theme.dart';
import 'package:flex_pilates_studio/controllers/auth_controller.dart';
import 'package:flex_pilates_studio/controllers/booking_controller.dart';
import 'package:flex_pilates_studio/controllers/session_controller.dart';
import 'package:flex_pilates_studio/controllers/waitlist_controller.dart';
import 'package:flex_pilates_studio/controllers/coach_controller.dart';
import 'package:flex_pilates_studio/controllers/admin_controller.dart';
import 'package:flex_pilates_studio/views/screens/member/member_home_screen.dart';
import 'package:flex_pilates_studio/views/screens/member/member_bookings_screen.dart';
import 'package:flex_pilates_studio/views/screens/member/member_waitlist_screen.dart';
import 'package:flex_pilates_studio/views/screens/auth/login_screen.dart';
import 'package:flex_pilates_studio/views/screens/coach/coach_home_screen.dart';
import 'package:flex_pilates_studio/views/screens/admin/admin_home_screen.dart';
import 'package:flex_pilates_studio/views/widgets/calendar_row.dart';
import 'support/preview_controllers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (call) async => call.method == 'getAll' ? <String, dynamic>{} : true,
      );
  setUpAll(() async {
    for (final entry in {
      'Inter': 'assets/fonts/Inter.ttf',
      'Manrope': 'assets/fonts/Manrope.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  setUpAll(
    () async => Supabase.initialize(
      url: 'https://example.invalid',
      anonKey: 'test-public-client-key',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      debug: false,
    ),
  );
  tearDownAll(() async => Supabase.instance.dispose());

  for (final width in [390.0, 1200.0]) {
    testWidgets(
      'member and staff screens render at $width without layout exceptions',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pages = <String, Widget>{
          'home': const MemberHomeScreen(),
          'bookings': const MemberBookingsScreen(),
          'waitlists': const MemberWaitlistScreen(),
          'login': const LoginScreen(),
          'coach': const CoachHomeScreen(),
          'admin': const AdminHomeScreen(),
        };
        for (final entry in pages.entries) {
          debugPrint('Review rendering: ${entry.key} at $width');
          final key = GlobalKey();
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthController>(
                  create: (_) => entry.key == 'login'
                      ? PreviewSignedOut()
                      : PreviewAuth(
                          role: entry.key == 'coach'
                              ? 'coach'
                              : entry.key == 'admin'
                              ? 'admin'
                              : 'member',
                        ),
                ),
                ChangeNotifierProvider<BookingController>(
                  create: (_) => PreviewBookings(),
                ),
                ChangeNotifierProvider<SessionController>(
                  create: (_) => PreviewSessions(),
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
              child: MaterialApp(
                theme: buildAppTheme(),
                debugShowCheckedModeBanner: false,
                home: RepaintBoundary(
                  key: key,
                  child: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 1100),
                      disableAnimations: true,
                    ),
                    child: entry.value,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (entry.key == 'home') {
            final calendar = tester.widget<CalendarRow>(
              find.byType(CalendarRow),
            );
            calendar.onSelected(DateTime.now().add(const Duration(days: 1)));
            await tester.pumpAndSettle();
          }
          await tester.runAsync(() async {
            for (final path in [
              'assets/images/pilates.jpg',
              'assets/images/padel.jpg',
            ]) {
              await precacheImage(AssetImage(path), key.currentContext!);
            }
          });
          await tester.pump();
          expect(tester.takeException(), isNull, reason: entry.key);
          if (const bool.fromEnvironment('CAPTURE_REVIEW')) {
            await tester.runAsync(() async {
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 1.5);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final directory = Directory('../design-review/implementation');
              await directory.create(recursive: true);
              await File(
                '${directory.path}/${entry.key}-${width.toInt()}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      },
    );
  }
}
