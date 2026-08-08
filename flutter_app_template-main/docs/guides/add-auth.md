# How to add authentication

Email/password against Supabase already works end to end. This covers extending
it — a new sign-in method, or a different backend entirely.

## What already exists

| Piece | File |
| --- | --- |
| Contract | `auth/auth_repository.dart` |
| Supabase implementation | `auth/supabase_auth_repository.dart` |
| SDK adapter | `supabase/supabase_auth_data_source.dart` |
| Fallback when unconfigured | `auth/unavailable_auth_repository.dart` |
| Token persistence | `auth/token_storage.dart` (secure storage) |
| App state | `viewmodels/auth_view_model.dart` |
| Redirects | `routes/route_guards.dart` |
| Screens | `views/auth/` |

## Adding a sign-in method (Google, Apple, magic link)

### 1. Extend the contract

```dart
// auth/auth_repository.dart
AsyncResult<AuthSession> signInWithGoogle();
```

Every implementation must now provide it — including
`UnavailableAuthRepository`, which returns the standard "not configured"
failure. The compiler will tell you.

### 2. Extend the data source

```dart
// supabase/supabase_auth_data_source.dart
Future<AuthSession> signInWithOAuth(sb.OAuthProvider provider) async {
  await _auth.signInWithOAuth(provider, redirectTo: _redirectUrl);
  // OAuth completes via deep link; the session arrives on onAuthStateChange.
  return _requireSession(_auth.currentSession);
}
```

### 3. Implement in the repository

```dart
@override
AsyncResult<AuthSession> signInWithGoogle() => _guard(() async {
      final session = await _dataSource.signInWithOAuth(sb.OAuthProvider.google);
      await _persist(session);
      return session;
    });
```

`_guard` handles the error mapping; `_persist` stores the tokens and publishes
the new `AuthStatus`.

### 4. Expose it on the view model, then the view

```dart
Future<bool> signInWithGoogle() async {
  final session = await runGuarded(_repository.signInWithGoogle, asBusy: true);
  return session != null;
}
```

```dart
AppButton.secondary(
  label: 'Continue with Google',
  icon: Icons.g_mobiledata,
  isLoading: viewModel.isBusy,
  onPressed: () => viewModel.signInWithGoogle(),
),
```

No navigation on success — the guard handles it.

## Replacing Supabase entirely

Write one class:

```dart
class FirebaseAuthRepository implements AuthRepository { ... }
```

Change one line in the service locator:

```dart
getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository(...));
```

No screen, view model or route changes. That is the entire point of the
interface.

## How the session lifecycle works

```
bootstrap → AuthRepository.restoreSession()
    valid?  → tokens mirrored to SecureStore → AuthStatus.authenticated
    no      → AuthStatus.unauthenticated
              ↓
RouteGuard (unknown ⇒ stay on splash) redirects
              ↓
request → AuthInterceptor attaches the bearer token
              ↓
401 → single-flight refresh → replay once
              ↓
refresh fails → signOut() → guard redirects to login
```

`AuthStatus.unknown` is what keeps the splash screen up during step one. Never
collapse it into `unauthenticated`, or returning users see the login screen
flash by.

## Security requirements

- Tokens in `SecureStore` (keychain/keystore) only. Never `SharedPreferences`.
- Never log a token. `AppLogger` redacts the common key names, but do not rely
  on it as your only defence.
- Clear tokens **and the cache** on sign-out — cached data belongs to a user.
- Sign-out must clear local state even if the remote call fails.
- Treat a token as expired one minute early so a request never dies in flight.
- Password reset must succeed even for unknown addresses, or the endpoint
  becomes an account-enumeration tool.
- Server-side authorization is the real control. Client checks are UX.

## Testing

`AuthRepository` is an interface, so a fake needs no SDK:

```dart
class FakeAuthRepository implements AuthRepository {
  AuthStatus _status = AuthStatus.unauthenticated;
  @override
  AuthStatus get currentStatus => _status;
  // …
}
```

`test/routes/route_guard_test.dart` shows the redirect rules being verified
against every combination of auth and onboarding state.
