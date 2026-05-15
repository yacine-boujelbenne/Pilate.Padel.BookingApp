import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../views/screens/admin/add_coach_screen.dart';
import '../views/screens/admin/admin_home_screen.dart';
import '../views/screens/admin/edit_coach_screen.dart';
import '../views/screens/admin/admin_sessions_screen.dart';
import '../views/screens/admin/edit_session_screen.dart';
import '../views/screens/admin/admin_new_session_screen.dart';
import '../views/screens/admin/member_detail_screen.dart';
import '../views/screens/auth/forgot_password_screen.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/register_screen.dart';
import '../views/screens/auth/reset_password_screen.dart';
import '../views/screens/auth/splash_screen.dart';
import '../views/screens/auth/welcome_screen.dart';
import '../views/screens/coach/coach_home_screen.dart';
import '../views/screens/coach/new_session_screen.dart';
import '../views/screens/common/manage_account_screen.dart';
import '../views/screens/common/session_attendees_screen.dart';
import '../views/screens/common/settings_screen.dart';
import '../views/screens/member/member_bookings_screen.dart';
import '../views/screens/member/chat_bot_screen.dart';
import '../views/screens/member/member_coach_detail_screen.dart';
import '../views/screens/member/member_explore_screen.dart';
import '../views/screens/member/member_home_screen.dart';
import '../views/screens/member/member_profile_screen.dart';
import '../views/screens/member/member_waitlist_screen.dart';
import '../views/screens/member/payment_success_screen.dart';

class AppRouter {
  AppRouter(this.authController);

  final AuthController authController;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authController,
    redirect: _redirect,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen()),
      GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsScreen(
                backTarget: (state.extra as String?) ?? '/login',
              )),
      GoRoute(
          path: '/account/manage',
          builder: (context, state) => ManageAccountScreen(
                backTarget: (state.extra as String?) ?? '/member/profile',
              )),
      GoRoute(
          path: '/member/home',
          builder: (context, state) => const MemberHomeScreen()),
      GoRoute(
          path: '/member/explore',
          builder: (context, state) => const MemberExploreScreen()),
      GoRoute(
          path: '/member/chatbot',
          builder: (context, state) => const ChatBotScreen()),
      GoRoute(
          path: '/member/coaches/:id',
          builder: (context, state) => MemberCoachDetailScreen(
                coachId: state.pathParameters['id']!,
              )),
      GoRoute(
          path: '/member/bookings',
          builder: (context, state) => const MemberBookingsScreen()),
      GoRoute(
          path: '/member/waitlists',
          builder: (context, state) => const MemberWaitlistScreen()),
      GoRoute(
          path: '/member/profile',
          builder: (context, state) => const MemberProfileScreen()),
      GoRoute(
          path: '/member/booking/new',
          builder: (context, state) => const MemberHomeScreen()),
      GoRoute(
        path: '/member/payment-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentSuccessScreen(
            sessionName: (extra['sessionName'] as String?) ?? 'Session',
            amount: (extra['amount'] as num?)?.toDouble() ?? 0,
            method: (extra['method'] as String?) ?? 'cash',
          );
        },
      ),
      GoRoute(
          path: '/coach/home',
          builder: (context, state) => const CoachHomeScreen()),
      GoRoute(
          path: '/coach/sessions/new',
          builder: (context, state) => const NewSessionScreen()),
      GoRoute(
          path: '/admin/home',
          builder: (context, state) => const AdminHomeScreen()),
      GoRoute(
          path: '/admin/coaches/new',
          builder: (context, state) => const AddCoachScreen()),
      GoRoute(
          path: '/admin/coaches/:id/edit',
          builder: (context, state) =>
              EditCoachScreen(coachId: state.pathParameters['id']!)),
      GoRoute(
          path: '/admin/sessions/new',
          builder: (context, state) => const AdminNewSessionScreen()),
      GoRoute(
          path: '/admin/sessions',
          builder: (context, state) => const AdminSessionsScreen()),
      GoRoute(
        path: '/admin/sessions/:id/edit',
        builder: (context, state) =>
            EditSessionScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/sessions/:id/attendees',
        builder: (context, state) => SessionAttendeesScreen(
          sessionId: state.pathParameters['id']!,
          backTarget: (state.extra as String?) ?? '/coach/home',
        ),
      ),
      GoRoute(
        path: '/admin/users/:id',
        builder: (context, state) =>
            MemberDetailScreen(userId: state.pathParameters['id']!),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final role = authController.profile?.role;
    final isLoggedIn = authController.user != null;
    final profileLoaded = authController.profileLoaded;
    final path = state.matchedLocation;

    final publicRoutes = {
      '/',
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password'
    };

    if (isLoggedIn && !profileLoaded) {
      return null;
    }

    if (!isLoggedIn && !publicRoutes.contains(path)) {
      return '/login';
    }

    if (isLoggedIn &&
        (path == '/login' || path == '/register' || path == '/')) {
      if (role == 'admin') return '/admin/home';
      if (role == 'coach') return '/coach/home';
      if (role == 'member') return '/member/home';
      return '/login';
    }

    if (isLoggedIn) {
      if (path.startsWith('/admin') && role != 'admin') {
        return role == 'coach'
            ? '/coach/home'
            : role == 'member'
                ? '/member/home'
                : '/login';
      }
      if (path.startsWith('/coach') && role != 'coach') {
        return role == 'admin'
            ? '/admin/home'
            : role == 'member'
                ? '/member/home'
                : '/login';
      }
      if (path.startsWith('/member') && role != 'member') {
        return role == 'admin'
            ? '/admin/home'
            : role == 'coach'
                ? '/coach/home'
                : '/login';
      }
    }

    return null;
  }
}
