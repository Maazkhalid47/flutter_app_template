# auth/

## Why it exists

Authentication, behind an interface. `AuthRepository` is what the app depends
on; Supabase is one implementation of it. Swapping providers, or running the
whole flow against a fake in tests, does not touch a single screen.

## What belongs here

| File | Purpose |
| --- | --- |
| `auth_repository.dart` | The contract: sign in/up/out, refresh, restore, profile |
| `supabase_auth_repository.dart` | Supabase implementation |
| `unavailable_auth_repository.dart` | Null-object used when Supabase is unconfigured |
| `auth_session.dart` | User + tokens + expiry |
| `token_storage.dart` | Credential persistence (`SecureTokenStorage`) |

The Supabase SDK adapter lives in `supabase/supabase_auth_data_source.dart`, so
this folder stays provider-neutral apart from the one implementation file.

## What does NOT belong here

- Login/sign-up screens (→ `views/auth/`).
- `AuthViewModel` (→ `viewmodels/`).
- Redirect rules (→ `routes/route_guards.dart`).

## Naming conventions

- Methods name the act: `signInWithEmail`, `signUpWithEmail`, `signOut`.
- Every method returns `AsyncResult<T>`; nothing throws across the boundary.
- `authStatusChanges` is the stream; `currentStatus` is the synchronous read.

## Example usage

```dart
final result = await authRepository.signInWithEmail(
  email: email,
  password: password,
);
result.when(
  success: (session) => log('signed in as ${session.user.email}'),
  failure: (error) => showError(error),
);
```

## Best practices

- `AuthStatus.unknown` exists so the router can hold the splash screen while a
  session is restored. Never collapse it into `unauthenticated` — that flashes
  the login screen at users who are already signed in.
- Tokens go to `SecureStore` only, never to `SharedPreferences`.
- Treat a token as expired one minute early (`AuthSession.isExpired`) so a
  request is never sent with a token that dies mid-flight.
- Clear the cache on sign-out — cached data belongs to a user.
- Sign-out must clear local state even if the network call fails.

See `docs/integrations/supabase.md` for the setup and `docs/guides/add-auth.md`
for adding a provider (Google, Apple, magic link).
