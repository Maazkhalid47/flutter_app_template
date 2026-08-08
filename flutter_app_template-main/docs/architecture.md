# Architecture

MVVM on top of Clean Architecture layering, with Provider for state and a single
composition root for dependencies.

## The layers

```
┌──────────────────────────────────────────────────────────┐
│ views/  widgets/  components/            PRESENTATION    │
│ Renders state. No logic, no try/catch, no HTTP.          │
└───────────────────────┬──────────────────────────────────┘
                        │ watch / read
┌───────────────────────▼──────────────────────────────────┐
│ viewmodels/  providers/                  PRESENTATION    │
│ Screen state + commands. No BuildContext, no Flutter UI. │
└───────────────────────┬──────────────────────────────────┘
                        │ Result<T>
┌───────────────────────▼──────────────────────────────────┐
│ repositories/  auth/  onboarding/        DOMAIN          │
│ Domain contracts. Caching. Errors → Result. No Flutter.  │
└───────────────────────┬──────────────────────────────────┘
                        │ throws
┌───────────────────────▼──────────────────────────────────┐
│ services/  api/  supabase/  stripe/      DATA            │
│ notifications/  storage/  cache/  network/               │
│ Talks to the outside world. Knows SDKs and JSON.         │
└──────────────────────────────────────────────────────────┘

models/  core/  enums/  exceptions/  utils/  constants/   ← used by all layers
```

**Dependencies point inward only.** A repository never imports a view model; a
model imports nothing.

## The two boundaries that matter

### 1. Exceptions stop at the repository

Services throw whatever the SDK throws. `BaseRepository.guard()` catches it,
`ExceptionMapper` converts it to a typed `AppException`, and it is returned
inside a `Result`. Above that line nothing throws and nothing catches — the
compiler forces every caller to handle the failure branch.

### 2. Foreign types stop at the data layer

`Dio`, `SupabaseClient` and Stripe types never appear above `api/`, `supabase/`
or `stripe/`. Adapters map them to app models at the edge. This is what makes
the backend replaceable and the upper layers testable with plain fakes.

## Request flow

A list screen loading data:

```
ArticleListView
  └─ context.watch(ArticleListViewModel)
       └─ ArticleListViewModel.load()
            └─ runGuarded(...)                     sets ViewState.loading
                 └─ ArticleRepository.fetchArticles()
                      └─ cachedFetch                fresh cache? return it
                           └─ ArticleApiService.fetchArticles()
                                └─ ApiClient.requestJsonList()
                                     └─ Dio  ← interceptors
                           └─ decode JSON → List<Article>
                           └─ write cache
            └─ Result.success                       sets ViewState.success/empty
  └─ StateView renders loading / empty / error / data
```

On failure the same path produces `Result.failure(NetworkException)`,
`ViewState.error`, and `AppErrorView` with a Retry button — because
`isRetryable` is true. Nothing along the way needed a `try`.

## State management

| Scope | Mechanism | Lifetime |
| --- | --- | --- |
| App-wide | `ThemeProvider`, `LocaleProvider`, `AuthViewModel` at the root | App |
| Screen | `ChangeNotifierProvider` created by the route | Route |
| Ephemeral UI | `StatefulWidget` state, controllers | Widget |

Screen view models are created in the route builder so they are disposed with
the route. Putting them at the root is the most common way a Provider app
starts leaking stale state.

## Navigation

`go_router` with a central `redirect`. `RouteGuard` is a pure function of
(auth status, onboarding flag, target location) — so signing out anywhere moves
every open screen to login, and the whole rule set is unit-tested without a
widget tree.

Screens never navigate on auth changes. One source of truth.

## Startup sequence

`bootstrap.dart`, in order — the order is load-bearing:

1. `AppConfig.initialize()` + validation (fails fast in release)
2. Supabase init (result decides which `AuthRepository` gets registered)
3. `ServiceLocator.setup()`
4. `GlobalErrorHandler.install()`
5. Theme, locale and onboarding flag loaded in parallel
6. Session restored — so the first frame is never the wrong screen
7. Non-blocking warm-up: analytics, payments, push, cache eviction

## SOLID in practice

- **S** — `services/` know *how*, repositories know *what*, view models know
  *when*, views know *how it looks*.
- **O** — new payment provider, analytics vendor or auth backend = a new
  implementation of an existing interface.
- **L** — `UnavailableAuthRepository` substitutes for the real one without any
  caller changing behaviour.
- **I** — `TokenStorage` exposes four methods, not all of `KeyValueStore`, so
  the auth interceptor cannot touch unrelated storage.
- **D** — everything depends on interfaces; concrete types are chosen once, in
  the service locator.

## What this architecture deliberately does not do

- No `build_runner`/codegen out of the box — models are hand-written so the
  template builds instantly on a fresh clone. Add `freezed`/`json_serializable`
  when the model count justifies it.
- No BLoC. Provider + `ChangeNotifier` is enough for MVVM and has far less
  ceremony; the view-model boundary is what matters, not the notifier type.
- No `flutter_stripe` or `firebase_messaging` dependency yet — the
  architecture is in place and documented, so adding them touches one file each.
