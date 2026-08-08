# Flutter App Template

A production-grade Flutter starter: **MVVM + Clean Architecture**, Provider for
state, `go_router` for navigation, and a single composition root for
dependencies. Supabase, Stripe and push notifications are architected in from
day one.

Built to be cloned and shipped, not read and adapted.

```
Flutter 3.44 · Dart 3.12 · analyze clean · 54 tests green
```

---

## Quick start

```bash
git clone https://github.com/Maazkhalid47/flutter_app_template.git my_app
cd my_app

flutter pub get
flutter gen-l10n

cp env/dev.json.example env/dev.json     # optional: add Supabase/Stripe keys
flutter run --dart-define-from-file=env/dev.json
```

It runs with **no configuration at all** — Supabase and Stripe features simply
report themselves as unavailable instead of crashing. Add keys when you need
them.

```bash
flutter analyze     # must print "No issues found!"
flutter test
```

---

## What you get

| Concern | Status |
| --- | --- |
| MVVM + Clean Architecture | Enforced by folder rules, with a working vertical slice |
| State management | Provider + `ChangeNotifier`, app-wide vs route-scoped separated |
| Navigation | `go_router` with pure, unit-tested redirect guards |
| Dependency injection | `get_it`, one composition root, constructor injection everywhere |
| Networking | `ApiClient` interface + Dio, with 4 interceptors in a deliberate order |
| Auth | Supabase email/password, secure token storage, single-flight 401 refresh |
| Error handling | Sealed `AppException` hierarchy, `Result<T>`, all 3 crash handlers |
| Offline | Two-tier TTL cache with stale-on-failure fallback |
| Theming | Light/dark, design tokens, semantic colour `ThemeExtension` |
| Localization | ARB-based, `en` + `ur` (RTL), runtime switching |
| Payments | Backend-first Stripe architecture, provider-agnostic interface |
| Notifications | Full app-side plumbing, tap→route with early-tap queueing |
| Responsive | Breakpoints, `ResponsiveLayout`, content width caps |
| Testing | Unit, repository, view model, route-guard and widget tests |
| Documentation | A README in every folder + 12 documents in `docs/` |

---

## Architecture in one diagram

```
views / widgets / components        ← renders state, no logic
        ↓ watch/read
viewmodels / providers              ← screen state, no BuildContext
        ↓ Result<T>
repositories / auth                 ← domain contracts, caching, error mapping
        ↓ throws
services / api / supabase / stripe  ← the outside world
```

Two boundaries hold it together:

1. **Exceptions stop at the repository.** Everything above receives
   `Result<Success | Failure>` and is forced by the compiler to handle both.
2. **Foreign types stop at the data layer.** No `Dio`, `SupabaseClient` or
   Stripe type appears above `api/`, `supabase/` or `stripe/`.

Full detail: [docs/architecture.md](docs/architecture.md).

---

## Documentation

### Start here

- [Architecture](docs/architecture.md) — layers, boundaries, request flow, startup
- [Folder structure](docs/folder-structure.md) — the map and a "where does this go?" table
- [Conventions](docs/conventions.md) — naming, standards, the 10 hard rules

### Recipes

- [Add a screen](docs/guides/add-a-screen.md)
- [Add an API endpoint](docs/guides/add-an-api.md)
- [Add a repository](docs/guides/add-a-repository.md)
- [Add a ViewModel](docs/guides/add-a-viewmodel.md)
- [Add a Provider](docs/guides/add-a-provider.md)
- [Add authentication](docs/guides/add-auth.md)

### Integrations

- [Supabase](docs/integrations/supabase.md) — setup, RLS, realtime, edge functions
- [Stripe](docs/integrations/stripe.md) — the security model, webhooks, native sheet
- [Notifications](docs/integrations/notifications.md) — FCM wiring, deep links

Every folder under `lib/` also has its own `README.md` explaining why it exists,
what belongs in it, and the mistakes to avoid.

---

## Project layout

```
lib/
├── main.dart · bootstrap.dart · app.dart
├── core/ config/ constants/ enums/ exceptions/     foundations
├── api/ network/ storage/ cache/                   infrastructure
├── models/ repositories/ services/                 data + domain
├── auth/ supabase/ stripe/ notifications/          integrations
├── permissions/ onboarding/                        features
├── viewmodels/ providers/ routes/                  presentation logic
├── views/ widgets/ components/ theme/              presentation
├── localization/ l10n/ generated/                  i18n
├── utils/ helpers/ extensions/ mixins/ validators/ support
└── dependency_injection/                           composition root
```

---

## The example slice

`Article` is a complete working vertical slice — API → service → repository →
view model → view — with pagination, search, caching, pull-to-refresh and error
states. It exists to be copied, then deleted.
[How to remove it](docs/folder-structure.md#deleting-the-example-slice).

---

## Environments

```bash
flutter run --dart-define-from-file=env/dev.json
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

Configuration is compiled in via `--dart-define`; nothing secret is ever
committed. A release build with a missing required key fails fast at startup
rather than at the first network call. See [env/README.md](env/README.md).

---

## Deliberate omissions

Honest about what is *not* here, and why:

- **No `build_runner`/codegen.** Models are hand-written so a fresh clone builds
  instantly. Add `freezed`/`json_serializable` when the model count justifies it.
- **No `flutter_stripe` / `firebase_messaging` dependency.** Both architectures
  are complete and documented; adding either SDK touches exactly one file, and
  until then the project builds on every platform with no Gradle or CocoaPods
  setup.
- **No BLoC.** Provider + `ChangeNotifier` is sufficient for MVVM with far less
  ceremony. The view-model boundary is what matters, not the notifier type.
- **`NoopAnalyticsService` by default.** Swap in your vendor in one line in the
  service locator.

---

## Requirements

- Flutter 3.44+ / Dart 3.12+
- Android SDK 21+ · iOS 13+ · modern browsers

## License

Add your license before publishing.
