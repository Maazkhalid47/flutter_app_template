import 'package:go_router/go_router.dart';

import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/home/home_screen.dart';
import '../views/onboarding/onboarding_screen.dart';
import '../views/splash/splash_screen.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
  ],
);
