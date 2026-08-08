# routes/

## Why it exists

One declaration of every screen the app can reach, and one place that decides
who may reach it. Auth-dependent navigation scattered across screens is how you
get a signed-out user still looking at private data.

## What belongs here

- `app_routes.dart` — path and name constants, and the public-route set.
- `app_router.dart` — the `GoRouter` instance, route tree and analytics observer.
- `route_guards.dart` — the pure redirect logic.

## What does NOT belong here

- Screens themselves (→ `views/`).
- Business rules that decide *what* to show; guards only decide *whether*.
- `Navigator.push` calls — navigate by name from the view.

## Naming conventions

| Thing | Convention | Example |
| --- | --- | --- |
| Path constant | `lowerCamelCase` → kebab-case value | `signUp = '/sign-up'` |
| Name constant | `<route>Name` | `signUpName = 'signUp'` |
| Path builder | `<route>Path(args)` | `articleDetailPath('42')` |

## Example usage

Add a screen:

```dart
// 1. app_routes.dart
static const String profile = '/profile';
static const String profileName = 'profile';

// 2. app_router.dart
GoRoute(
  path: AppRoutes.profile,
  name: AppRoutes.profileName,
  builder: (context, state) => const ProfileView(),
),
```

Navigate:

```dart
context.pushNamed(AppRoutes.profileName);              // adds to the stack
context.goNamed(AppRoutes.homeName);                   // replaces the stack
context.pushNamed(AppRoutes.articleDetailName,
    pathParameters: {'id': article.id});
```

## Best practices

- A new screen is private by default. Add it to `publicPaths` only if a
  signed-out user genuinely should see it.
- Never navigate on auth success — flip the auth state and let the guard move
  the user. Two sources of navigation truth means flicker and race conditions.
- Create route-scoped view models in the route builder, not in the widget, so
  they are disposed with the route.
- Every redirect target must be stable: `redirect(redirect(x))` has to be null.
  `test/routes/route_guard_test.dart` asserts this.
