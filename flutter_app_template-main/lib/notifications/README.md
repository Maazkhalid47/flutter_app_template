# notifications/

## Why it exists

Push notifications behind an interface, plus the piece everyone forgets: turning
a notification tap into navigation, safely, even when the tap arrives before the
router exists.

## What belongs here

| File | Purpose |
| --- | --- |
| `push_notification_service.dart` | Interface + default (provider-less) implementation |
| `notification_payload.dart` | Normalised payload: FCM/APNs/OneSignal all map to this |
| `notification_router.dart` | Tap → route, with queueing before the router is ready |

## The three cases, and why they are separate streams

| Stream | When | What to do |
| --- | --- | --- |
| `onForegroundMessage` | App open | Show an in-app banner. **Do not navigate** |
| `onNotificationOpened` | User tapped | Navigate |
| `onTokenRefresh` | Token rotated | Re-register with the backend |

Plus `getInitialNotification()` — the notification that launched the app from a
terminated state. It never arrives on a stream and must be checked once at
startup, which `NotificationRouter.start()` does.

## Current state

The default implementation wires up everything app-side (registration, token
storage, analytics, streams) with no provider SDK, so the template builds
everywhere out of the box. Four `TODO(fcm)` points mark exactly where
`firebase_messaging` plugs in. Nothing outside this folder changes.

## Naming conventions

- The server sends the in-app path as `route` in the data payload, so deep-link
  handling is data rather than a growing `switch`.
- `emitForeground` / `emitOpened` / `emitToken` are the entry points the SDK
  wiring calls.

## Example usage

```dart
// Ask at a moment the user understands why — never on first launch.
final granted = await pushService.requestPermission();
if (granted) {
  final token = await pushService.getToken();
  if (token != null) await pushService.registerDevice(token);
}
```

## Best practices

- Request permission contextually. A first-launch prompt is denied far more
  often, and on iOS a denial is close to permanent.
- Registration failures are logged, never fatal: missed notifications are not a
  broken app.
- Clear the token on sign-out, or the next user on a shared device receives the
  previous user's notifications.
- Validate any deep link from a payload — a stale route should land on
  `NotFoundView`, not crash.

Setup: `docs/integrations/notifications.md`.
