import 'dart:async';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../core/disposable.dart';
import '../enums/http_method.dart';
import '../services/analytics_service.dart';
import '../storage/key_value_store.dart';
import '../utils/logger.dart';
import 'notification_payload.dart';

/// Push notifications, provider-agnostic.
///
/// The three streams exist because the three cases need different handling and
/// conflating them is a classic source of bugs:
/// * [onForegroundMessage] — app is open; show an in-app banner, do not navigate.
/// * [onNotificationOpened] — user tapped; navigate.
/// * [onTokenRefresh] — the device token rotated; re-register it.
abstract interface class PushNotificationService implements Disposable {
  Future<void> initialize();

  /// Asks the OS for permission. Returns whether it was granted.
  ///
  /// Call this at a moment the user understands *why* — after they enable a
  /// feature that needs it, never on first launch.
  Future<bool> requestPermission();

  Future<bool> get hasPermission;

  /// The current device token, or `null` when permission was denied.
  Future<String?> getToken();

  /// Sends the token to your backend so it can target this device.
  Future<void> registerDevice(String token);

  /// Topic subscription, for broadcast notifications.
  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  /// The notification that launched the app from a terminated state, if any.
  /// Must be checked once at startup — it never arrives on a stream.
  Future<NotificationPayload?> getInitialNotification();

  Stream<NotificationPayload> get onForegroundMessage;

  Stream<NotificationPayload> get onNotificationOpened;

  Stream<String> get onTokenRefresh;

  /// Clears the token on sign-out, so the next user does not receive the
  /// previous user's notifications on a shared device.
  Future<void> clearToken();
}

/// The default implementation: wires up the app-side plumbing (registration,
/// storage, analytics, streams) and leaves the provider SDK unimplemented.
///
/// The app runs and builds on every platform with this in place. To go live,
/// add `firebase_messaging`, then fill in the four `TODO(fcm)` points below —
/// nothing outside this file changes.
///
/// See `docs/integrations/notifications.md` for the full checklist.
class DefaultPushNotificationService implements PushNotificationService {
  DefaultPushNotificationService({
    required ApiClient apiClient,
    required KeyValueStore store,
    required AnalyticsService analytics,
    required AppLogger logger,
  }) : _apiClient = apiClient,
       _store = store,
       _analytics = analytics,
       _logger = logger;

  final ApiClient _apiClient;
  final KeyValueStore _store;
  final AnalyticsService _analytics;
  final AppLogger _logger;

  final StreamController<NotificationPayload> _foregroundController =
      StreamController<NotificationPayload>.broadcast();
  final StreamController<NotificationPayload> _openedController =
      StreamController<NotificationPayload>.broadcast();
  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  bool _initialized = false;

  @override
  Stream<NotificationPayload> get onForegroundMessage =>
      _foregroundController.stream;

  @override
  Stream<NotificationPayload> get onNotificationOpened =>
      _openedController.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // TODO(fcm): await Firebase.initializeApp(), then forward
    // FirebaseMessaging.onMessage / onMessageOpenedApp / onTokenRefresh into
    // the controllers below via `emitForeground`, `emitOpened`, `emitToken`.
    _logger.info(
      'Push notifications initialised without a provider SDK. '
      'See docs/integrations/notifications.md.',
    );
  }

  @override
  Future<bool> requestPermission() async {
    // TODO(fcm): FirebaseMessaging.instance.requestPermission().
    await _store.writeBool(StorageKeys.pushPermissionAsked, value: true);
    return false;
  }

  @override
  Future<bool> get hasPermission async => false;

  @override
  Future<String?> getToken() async {
    // TODO(fcm): return FirebaseMessaging.instance.getToken().
    return _store.readString(StorageKeys.pushToken);
  }

  @override
  Future<void> registerDevice(String token) async {
    // Skip the round trip when the backend already has this exact token.
    final stored = await _store.readString(StorageKeys.pushToken);
    if (stored == token) return;
    try {
      await _apiClient.requestJson(
        HttpMethod.post,
        ApiConstants.registerDevice,
        body: {'token': token},
      );
      await _store.writeString(StorageKeys.pushToken, token);
      _logger.info('Device registered for push notifications.');
    } catch (error) {
      // Never fatal: failing to register means missed notifications, not a
      // broken app. The next launch retries.
      _logger.warning('Device registration failed', data: {'error': '$error'});
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    // TODO(fcm): FirebaseMessaging.instance.subscribeToTopic(topic).
    _logger.debug('subscribeToTopic($topic) — no provider configured.');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    // TODO(fcm): FirebaseMessaging.instance.unsubscribeFromTopic(topic).
    _logger.debug('unsubscribeFromTopic($topic) — no provider configured.');
  }

  @override
  Future<NotificationPayload?> getInitialNotification() async {
    // TODO(fcm): FirebaseMessaging.instance.getInitialMessage().
    return null;
  }

  @override
  Future<void> clearToken() async {
    // TODO(fcm): FirebaseMessaging.instance.deleteToken().
    await _store.delete(StorageKeys.pushToken);
  }

  /// Entry points for the provider SDK. Kept public so the FCM wiring added in
  /// [initialize] can push events in without touching the stream controllers.
  void emitForeground(NotificationPayload payload) {
    if (_foregroundController.isClosed) return;
    _foregroundController.add(payload);
  }

  void emitOpened(NotificationPayload payload) {
    if (_openedController.isClosed) return;
    _openedController.add(payload);
    unawaited(
      _analytics.logEvent(
        AnalyticsEvent.notificationOpened,
        parameters: {'id': payload.id},
      ),
    );
  }

  void emitToken(String token) {
    if (_tokenController.isClosed) return;
    _tokenController.add(token);
    unawaited(registerDevice(token));
  }

  @override
  Future<void> dispose() async {
    await _foregroundController.close();
    await _openedController.close();
    await _tokenController.close();
  }
}
