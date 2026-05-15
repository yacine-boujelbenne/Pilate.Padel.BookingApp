import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/coach_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/waitlist_controller.dart';
import 'services/notification_service.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  AuthController? _authController;
  LocaleController? _localeController;
  GoRouter? _router;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await dotenv.load(fileName: '.env');

      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      );

      if (!kIsWeb) {
        try {
          await Firebase.initializeApp();
        } catch (_) {}
      }

      final authController = AuthController()..listenAuthState();
      final localeController = LocaleController()..loadLocale();
      final appRouter = AppRouter(authController);

      authController.passwordRecoveryStream.listen((_) {
        appRouter.router.go('/reset-password');
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _authController = authController;
        _localeController = localeController;
        _router = appRouter.router;
      });

      unawaited(() async {
        try {
          await NotificationService.instance.initialize();
        } catch (_) {
          // Push notifications are optional and should never block app startup.
        }
      }());
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authController != null &&
        _localeController != null &&
        _router != null) {
      return FlexPilatesApp(
        authController: _authController!,
        router: _router!,
        localeController: _localeController!,
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.sageDark,
                AppColors.sage,
                AppColors.sagePale,
              ],
            ),
          ),
          child: Center(
            child: _error == null
                ? const CircularProgressIndicator(color: AppColors.white)
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Startup failed: $_error',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class FlexPilatesApp extends StatelessWidget {
  final AuthController authController;
  final GoRouter router;
  final LocaleController localeController;

  const FlexPilatesApp({
    super.key,
    required this.authController,
    required this.router,
    required this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider(create: (_) => SessionController()),
        ChangeNotifierProvider(create: (_) => BookingController()),
        ChangeNotifierProvider(create: (_) => WaitlistController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => CoachController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: Consumer<LocaleController>(
        builder: (context, localeController, _) {
          return MaterialApp.router(
            title: 'Fléx Pilates Studio',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            routerConfig: router,
            locale: localeController.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('fr'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
