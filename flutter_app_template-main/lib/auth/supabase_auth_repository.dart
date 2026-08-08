import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/result.dart';
import '../core/typedefs.dart';
import '../enums/auth_status.dart';
import '../exceptions/app_exception.dart';
import '../exceptions/exception_mapper.dart';
import '../models/app_user.dart';
import '../services/analytics_service.dart';
import '../supabase/supabase_auth_data_source.dart';
import '../utils/logger.dart';
import 'auth_repository.dart';
import 'auth_session.dart';
import 'token_storage.dart';

/// [AuthRepository] on top of Supabase.
///
/// This is the layer that turns SDK behaviour into app behaviour: it converts
/// thrown SDK errors into `Result`, mirrors tokens into [TokenStorage] so the
/// REST client can authenticate too, and broadcasts a single [AuthStatus]
/// stream the router can trust.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseAuthDataSource dataSource,
    required TokenStorage tokenStorage,
    required AnalyticsService analytics,
    required AppLogger logger,
  }) : _dataSource = dataSource,
       _tokenStorage = tokenStorage,
       _analytics = analytics,
       _logger = logger {
    _subscription = _dataSource.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (Object error, StackTrace stackTrace) => _logger.error(
        'Auth state stream failed',
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  final SupabaseAuthDataSource _dataSource;
  final TokenStorage _tokenStorage;
  final AnalyticsService _analytics;
  final AppLogger _logger;

  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();
  StreamSubscription<sb.AuthState>? _subscription;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;

  @override
  Stream<AuthStatus> get authStatusChanges => _statusController.stream;

  @override
  AuthStatus get currentStatus => _status;

  @override
  AppUser? get currentUser => _user;

  @override
  AsyncResult<AuthSession?> restoreSession() => _guard(() async {
    final session = _dataSource.currentSession;
    if (session == null || !session.isValid) {
      await _clearLocalSession();
      return null;
    }
    await _persist(session);
    return session;
  });

  @override
  AsyncResult<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    final session = await _dataSource.signInWithPassword(email, password);
    await _persist(session);
    unawaited(_analytics.logEvent(AnalyticsEvent.signInCompleted));
    return session;
  });

  @override
  AsyncResult<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) => _guard(() async {
    final session = await _dataSource.signUp(email, password, displayName);
    await _persist(session);
    unawaited(_analytics.logEvent(AnalyticsEvent.signUpCompleted));
    return session;
  });

  @override
  AsyncResult<void> sendPasswordReset(String email) =>
      _guard(() => _dataSource.resetPassword(email));

  @override
  AsyncResult<AuthSession> refreshSession() => _guard(() async {
    final session = await _dataSource.refresh();
    await _persist(session);
    return session;
  });

  @override
  AsyncResult<void> signOut() => _guard(() async {
    await _dataSource.signOut();
    await _clearLocalSession();
    unawaited(_analytics.logEvent(AnalyticsEvent.signOut));
    unawaited(_analytics.setUserId(null));
  });

  @override
  AsyncResult<AppUser> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) => _guard(() async {
    final user = await _dataSource.updateUser(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    _user = user;
    return user;
  });

  @override
  AsyncResult<void> deleteAccount() async => const Result.failure(
    AuthException(
      message:
          'Account deletion requires a privileged backend endpoint. '
          'See docs/integrations/supabase.md.',
    ),
  );

  /// Mirrors the session into secure storage and publishes the new status.
  Future<void> _persist(AuthSession session) async {
    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    _user = session.user;
    unawaited(_analytics.setUserId(session.user.id));
    _emit(AuthStatus.authenticated);
  }

  Future<void> _clearLocalSession() async {
    await _tokenStorage.clear();
    _user = null;
    _emit(AuthStatus.unauthenticated);
  }

  void _handleAuthStateChange(sb.AuthState state) {
    switch (state.event) {
      case sb.AuthChangeEvent.signedIn:
      case sb.AuthChangeEvent.tokenRefreshed:
      case sb.AuthChangeEvent.userUpdated:
        final session = _dataSource.currentSession;
        if (session != null) unawaited(_persist(session));
      case sb.AuthChangeEvent.signedOut:
        unawaited(_clearLocalSession());
      default:
        // Password recovery and MFA events do not change signed-in status.
        break;
    }
  }

  void _emit(AuthStatus status) {
    if (_status == status) return;
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  /// The single try/catch for this repository. Everything the SDK throws is
  /// mapped once, here, instead of at every call site.
  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result<T>.success(await operation());
    } catch (error, stackTrace) {
      final exception = ExceptionMapper.map(error, stackTrace);
      _logger.warning('Auth operation failed: ${exception.message}');
      if (exception is UnauthorizedException) await _clearLocalSession();
      return Result<T>.failure(exception);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
  }
}
