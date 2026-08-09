import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../cache/onboarding_prefs.dart';
import '../../constant/app_color/app_colors.dart';
import '../../repository/auth_repository.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (AuthRepository.instance.isAuthenticated) {
      context.go(AppRoutes.home);
      return;
    }

    final hasSeenOnboarding = await OnboardingPrefs.hasSeenOnboarding();
    if (!mounted) return;
    context.go(hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            // logo.jpeg (not .png) — matches actual filename in assets/images
            child: Image.asset(
              'assets/images/logo.jpeg',
              width: 220,
            ),
          ),
        ),
      ),
    );
  }
}