# permissions/

## Why it exists

OS permission requests behind an interface, with a closed set of permissions the
app is allowed to ask for.

## What belongs here

| File | Purpose |
| --- | --- |
| `permission_service.dart` | `AppPermission` enum, `PermissionService`, implementation |

## Why a closed enum

Every permission must also be declared in `AndroidManifest.xml` and iOS
`Info.plist` with a usage description. Requesting one that is not declared
fails silently on Android and **rejects the build at App Store review** on iOS.

Forcing the addition through `AppPermission` makes that a deliberate edit in one
place, with the manifest work attached to it — rather than something a
call site adds by accident.

## Naming conventions

- `AppPermission` values are what the *app* needs (`location`), not what the
  platform calls them (`locationWhenInUse`). The mapping is internal.

## Example usage

```dart
final result = await permissionService.request(AppPermission.camera);

result.when(
  success: (granted) {
    if (granted) openCamera();
  },
  failure: (error) async {
    if (error is PermissionException && error.isPermanentlyDenied) {
      final go = await FeedbackHelper.confirm(
        context,
        title: 'Camera access needed',
        message: 'Enable camera access in Settings to continue.',
      );
      if (go) await permissionService.openSettings();
    }
  },
);
```

## Best practices

- A denial is `Result.success(false)`, not a failure — being told "no" is a
  normal outcome. Only a *permanent* denial is a `PermissionException`, because
  only then does the UI need to behave differently.
- Ask in context, right after the user does something that needs it. A prompt
  on first launch is denied far more often, and on iOS you rarely get a second
  chance.
- Handle permanent denial explicitly: re-requesting does nothing, so offer
  `openSettings()`.
- Re-check on resume. The user may have changed the setting while away.
- Adding a permission means three edits: the enum, `AndroidManifest.xml`, and
  `Info.plist` with a human usage string.
