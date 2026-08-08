# Push notifications

## What the template provides

All the app-side plumbing, with no provider SDK attached:

| File | Role |
| --- | --- |
| `notifications/push_notification_service.dart` | Interface + default implementation |
| `notifications/notification_payload.dart` | Normalised payload shape |
| `notifications/notification_router.dart` | Tap → route, with early-tap queueing |

The default implementation handles device registration, token storage,
deduplication, analytics and the three event streams. Four `TODO(fcm)` markers
show exactly where Firebase plugs in. Nothing outside that file changes.

## The three cases

| Case | Stream | Correct behaviour |
| --- | --- | --- |
| App open | `onForegroundMessage` | In-app banner. **Do not navigate** |
| App backgrounded, user taps | `onNotificationOpened` | Navigate |
| App terminated, user taps | `getInitialNotification()` | Navigate — checked once at startup |
| Token rotated | `onTokenRefresh` | Re-register with the backend |

Conflating the first two is the classic bug: the app yanks the user to another
screen mid-task because a notification arrived.

`NotificationRouter` also solves the ordering problem — a launch tap happens
before the router exists, so it is queued and replayed once
`attachNavigator` is called from `app.dart`.

## Adding Firebase Cloud Messaging

### 1. Firebase project

Create one, add Android and iOS apps, then:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This writes `google-services.json`, `GoogleService-Info.plist` and
`firebase_options.dart`.

### 2. Dependencies

```bash
flutter pub add firebase_core firebase_messaging flutter_local_notifications
```

`flutter_local_notifications` is what actually displays a banner while the app
is in the foreground — FCM does not do that for you on Android.

### 3. Wire it up

In `DefaultPushNotificationService.initialize`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

FirebaseMessaging.onMessage.listen(
  (message) => emitForeground(NotificationPayload.fromData(
    message.data,
    id: message.messageId,
  )),
);

FirebaseMessaging.onMessageOpenedApp.listen(
  (message) => emitOpened(NotificationPayload.fromData(
    message.data,
    id: message.messageId,
  )),
);

FirebaseMessaging.instance.onTokenRefresh.listen(emitToken);
```

Then fill in `requestPermission`, `getToken`, `getInitialNotification`,
`subscribeToTopic` and `clearToken` with their FCM equivalents.

### 4. Background handler

Must be a **top-level function**, annotated, registered in `main.dart`:

```dart
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Runs in a separate isolate: no access to your app's state or providers.
}

FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
```

### 5. Platform config

**Android** — `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Android 13+ requires a runtime prompt; `AppPermission.notifications` covers it.

**iOS** — enable Push Notifications and Background Modes → Remote notifications
in Xcode, and upload an APNs key to Firebase. **Push does not work in the iOS
simulator** — test on a device.

## Payload contract

Agree this with your backend:

```json
{
  "notification": { "title": "New order", "body": "Order #1234 confirmed" },
  "data": {
    "id": "notif_abc123",
    "route": "/orders/1234",
    "type": "order_confirmed"
  }
}
```

`route` is the app's own convention: the server sends the in-app path, so deep
linking is data rather than a `switch` that grows forever.

## Best practices

- Ask for permission **in context**, right after the user enables something that
  needs it. A first-launch prompt is denied far more often, and on iOS a denial
  is close to permanent.
- Registration failures are logged, never fatal — missed notifications are not
  a broken app. The next launch retries.
- Clear the token on sign-out, or the next user on a shared device receives the
  previous user's notifications.
- Validate a route from a payload before navigating; a stale link should land
  on `NotFoundView`.
- The background handler runs in its own isolate: no providers, no service
  locator, no app state.

## Checklist

- [ ] `google-services.json` / `GoogleService-Info.plist` in place and gitignored
- [ ] APNs key uploaded to Firebase
- [ ] Background handler top-level and `@pragma('vm:entry-point')`
- [ ] Permission requested contextually
- [ ] Token registered on sign-in, cleared on sign-out
- [ ] Deep links tested from foreground, background and terminated
- [ ] Tested on a physical iOS device
