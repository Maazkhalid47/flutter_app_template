import 'package:flutter_app_template/core/result.dart';
import 'package:flutter_app_template/core/typedefs.dart';
import 'package:flutter_app_template/enums/auth_status.dart';
import 'package:flutter_app_template/onboarding/onboarding_repository.dart';
import 'package:flutter_app_template/routes/app_routes.dart';
import 'package:flutter_app_template/routes/route_guards.dart';
import 'package:flutter_test/flutter_test.dart';

/// A hand-written fake rather than a mock: the behaviour is one boolean, and a
/// fake reads better than three `when(...)` lines.
class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository({required bool completed}) : _completed = completed;

  bool _completed;

  @override
  bool get hasCompletedOnboarding => _completed;

  @override
  Future<bool> load() async => _completed;

  @override
  AsyncResult<void> markCompleted() async {
    _completed = true;
    return const Result.success(null);
  }

  @override
  AsyncResult<void> reset() async {
    _completed = false;
    return const Result.success(null);
  }
}

/// Redirect rules are pure logic, and getting them wrong means either a
/// redirect loop or a screen a signed-out user can reach. Both are cheap to
/// catch here and expensive to catch by hand.
void main() {
  RouteGuard buildGuard({
    required AuthStatus status,
    required bool onboarded,
  }) => RouteGuard(
    authStatus: () => status,
    onboarding: _FakeOnboardingRepository(completed: onboarded),
  );

  group('session not yet resolved', () {
    test('holds on splash', () {
      final guard = buildGuard(status: AuthStatus.unknown, onboarded: true);
      expect(guard.redirect(AppRoutes.splash), isNull);
    });

    test('sends every other route back to splash', () {
      final guard = buildGuard(status: AuthStatus.unknown, onboarded: true);
      expect(guard.redirect(AppRoutes.home), AppRoutes.splash);
      expect(guard.redirect(AppRoutes.login), AppRoutes.splash);
    });
  });

  group('onboarding incomplete', () {
    test('forces onboarding even for a signed-in user', () {
      final guard = buildGuard(
        status: AuthStatus.authenticated,
        onboarded: false,
      );
      expect(guard.redirect(AppRoutes.home), AppRoutes.onboarding);
    });

    test('allows the onboarding route itself (no loop)', () {
      final guard = buildGuard(
        status: AuthStatus.unauthenticated,
        onboarded: false,
      );
      expect(guard.redirect(AppRoutes.onboarding), isNull);
    });
  });

  group('signed out', () {
    late RouteGuard guard;

    setUp(() {
      guard = buildGuard(status: AuthStatus.unauthenticated, onboarded: true);
    });

    test('private routes redirect to login', () {
      expect(guard.redirect(AppRoutes.home), AppRoutes.login);
      expect(guard.redirect(AppRoutes.settings), AppRoutes.login);
      expect(guard.redirect(AppRoutes.articles), AppRoutes.login);
    });

    test('public auth routes are allowed', () {
      expect(guard.redirect(AppRoutes.login), isNull);
      expect(guard.redirect(AppRoutes.signUp), isNull);
      expect(guard.redirect(AppRoutes.forgotPassword), isNull);
    });

    test('splash resolves to login', () {
      expect(guard.redirect(AppRoutes.splash), AppRoutes.login);
    });
  });

  group('signed in', () {
    late RouteGuard guard;

    setUp(() {
      guard = buildGuard(status: AuthStatus.authenticated, onboarded: true);
    });

    test('private routes are allowed', () {
      expect(guard.redirect(AppRoutes.home), isNull);
      expect(guard.redirect(AppRoutes.settings), isNull);
    });

    test('auth routes redirect home', () {
      expect(guard.redirect(AppRoutes.login), AppRoutes.home);
      expect(guard.redirect(AppRoutes.signUp), AppRoutes.home);
    });

    test('splash resolves home', () {
      expect(guard.redirect(AppRoutes.splash), AppRoutes.home);
    });

    test('a redirect target never redirects again', () {
      // Guards against infinite loops: whatever the guard returns must itself
      // be a stable destination.
      for (final location in [AppRoutes.home, AppRoutes.login]) {
        final target = guard.redirect(location);
        if (target != null) expect(guard.redirect(target), isNull);
      }
    });
  });
}
