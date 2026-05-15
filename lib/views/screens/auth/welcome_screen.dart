import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/locale_text.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _shineAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for content
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
    );

    // Shine animation for the logo
    _shineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _shineAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(
          parent: _shineAnimationController, curve: Curves.easeInOut),
    );

    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _shineAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (fill the whole screen)
          Positioned.fill(
            child: Container(
              constraints: const BoxConstraints.expand(),
              decoration: BoxDecoration(
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
            ),
          ),

          // Animated content
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Branding
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _fadeAnimationController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.sageDark.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              'Fléx',
                              style: AppTextStyles.logoTitle.copyWith(
                                fontSize: 72,
                                color: AppColors.sageDark,
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _shineAnimation,
                            builder: (context, child) {
                              return ClipOval(
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      stops: [
                                        0.0,
                                        (_shineAnimation.value - 0.1)
                                            .clamp(0.0, 1.0),
                                        _shineAnimation.value.clamp(0.0, 1.0),
                                        (_shineAnimation.value + 0.1)
                                            .clamp(0.0, 1.0),
                                        1.0,
                                      ],
                                      colors: [
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.4),
                                        Colors.transparent,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tagline
                    Text(
                      context.t('Pilates Studio', 'Studio de Pilates'),
                      style: AppTextStyles.screenTitle.copyWith(
                        fontSize: 24,
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.t(
                        'Your journey to strength and flexibility starts here',
                        'Votre parcours vers la force et la souplesse commence ici',
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Button
                    SizedBox(
                      width: 280,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          context.t('Sign In', 'Se connecter'),
                          style: AppTextStyles.buttonPrimary.copyWith(
                            fontSize: 14,
                            color: AppColors.sageDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Register Button
                    SizedBox(
                      width: 280,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.go('/register'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.white,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          context.t('Create Account', 'Créer un compte'),
                          style: AppTextStyles.buttonSecondary.copyWith(
                            fontSize: 14,
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
