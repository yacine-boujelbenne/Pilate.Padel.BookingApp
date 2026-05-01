import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      if (auth.user == null) {
        context.go('/login');
        return;
      }
      final role = auth.profile?.role;
      if (role == 'admin') {
        context.go('/admin/home');
      } else if (role == 'coach') {
        context.go('/coach/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageDark,
      body: Center(
        child: Text('Fléx', style: AppTextStyles.logoTitle),
      ),
    );
  }
}
