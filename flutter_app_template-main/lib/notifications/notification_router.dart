import 'dart:async';

import '../utils/logger.dart';
import 'notification_payload.dart';
import 'push_notification_service.dart';

/// Turns notification taps into navigation.
///
/// Kept apart from [PushNotificationService] on purpose: the service knows how
/// messages arrive, this knows what the app should do about them. It also
/// solves the ordering problem — a notification can open the app before the
/// router exists, so taps that arrive too early are held in [_pending] and
/// replayed once navigation is ready.
class NotificationRouter {
  NotificationRouter({
    required PushNotificationService service,
    required AppLogger logger,
  }) : _service = service,
       _logger = logger;

  final PushNotificationService _service;
  final AppLogger _logger;

  StreamSubscription<NotificationPayload>? _subscription;
  void Function(String route)? _navigate;
  NotificationPayload? _pending;

  /// Starts listening. Call during bootstrap, before the first frame.
  Future<void> start() async {
    _subscription = _service.onNotificationOpened.listen(_handle);
    final initial = await _service.getInitialNotification();
    if (initial != null) _handle(initial);
  }

  /// Supplies the navigation callback once the router is built, and flushes
  /// anything that arrived first.
  void attachNavigator(void Function(String route) navigate) {
    _navigate = navigate;
    final pending = _pending;
    if (pending != null) {
      _pending = null;
      _handle(pending);
    }
  }

  void _handle(NotificationPayload payload) {
    if (!payload.hasDeepLink) {
      _logger.debug('Notification ${payload.id} has no route; ignoring tap.');
      return;
    }
    final navigate = _navigate;
    if (navigate == null) {
      _pending = payload;
      return;
    }
    _logger.info('Opening ${payload.deepLink} from notification.');
    navigate(payload.deepLink!);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _navigate = null;
  }
}
