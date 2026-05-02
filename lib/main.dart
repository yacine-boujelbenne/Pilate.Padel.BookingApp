import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/coach_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/waitlist_controller.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config files might not be present during local setup.
  }

  await NotificationService.instance.initialize();

  final authController = AuthController()..listenAuthState();
  final appRouter = AppRouter(authController);

  runApp(
      FlexPilatesApp(authController: authController, router: appRouter.router));
}

class FlexPilatesApp extends StatelessWidget {
  final AuthController authController;
  final GoRouter router;

  const FlexPilatesApp({
    super.key,
    required this.authController,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider(create: (_) => SessionController()),
        ChangeNotifierProvider(create: (_) => BookingController()),
        ChangeNotifierProvider(create: (_) => WaitlistController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => CoachController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: MaterialApp.router(
        title: 'Fléx Pilates Studio',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
      ),
    );
  }
}
