# Folder structure

Every folder listed here has its own `README.md` with the full rules. This page
is the map and the "where does this file go?" decision table.

## Layout

```
lib/
├── main.dart                  Entry point + runZonedGuarded
├── bootstrap.dart             Ordered startup sequence
├── app.dart                   Root widget: providers, router, MaterialApp
│
├── core/                      Result, typedefs, Disposable — depends on nothing
├── config/                    AppConfig (--dart-define) + validation
├── constants/                 Compile-time values: api, storage keys, ui, assets
├── enums/                     Closed value sets
├── exceptions/                AppException hierarchy, mapper, global handler
│
├── api/                       ApiClient interface + Dio implementation
├── network/                   Connectivity + interceptors (auth, retry, logging)
├── storage/                   KeyValueStore: preferences + secure
├── cache/                     TTL cache with offline fallback
│
├── models/                    Immutable domain types
├── repositories/              Domain contracts, error mapping, caching
├── services/                  Endpoint groups, analytics
│
├── auth/                      AuthRepository, session, token storage
├── supabase/                  All Supabase SDK code
├── stripe/                    PaymentService + Stripe implementation
├── notifications/             Push service + notification → route
├── permissions/               OS permissions behind an interface
├── onboarding/                Feature-first: repo + view + page data
│
├── viewmodels/                BaseViewModel + one per screen
├── providers/                 App-wide notifiers + provider wiring
├── routes/                    Paths, router, guards
├── views/                     Screens, one folder per feature
├── widgets/                   Generic UI (app-agnostic)
├── components/                Composed UI (knows your models)
│
├── theme/                     Colours, typography, ThemeData
├── localization/              Localization workflow docs + helpers
├── l10n/                      .arb source strings
├── generated/                 Tool output — never edit
│
├── utils/                     Pure helpers (logger, formatters, debouncer)
├── helpers/                   Context-dependent helpers (snackbars, dialogs)
├── extensions/                Extension methods
├── mixins/                    Shared behaviour
├── validators/                Pure input rules
└── dependency_injection/      The single composition root

assets/                        images/ and icons/
docs/                          This documentation
env/                           Per-environment --dart-define files
test/                          Mirrors lib/
```

## Where does my file go?

| I am writing… | Folder |
| --- | --- |
| A screen | `views/<feature>/` |
| A button/input usable in any app | `widgets/` |
| A card that renders one of my models | `components/` |
| Screen state and commands | `viewmodels/` |
| App-wide state with no screen | `providers/` |
| A data type from the API | `models/` |
| HTTP paths for an endpoint group | `services/` |
| The domain contract over that group | `repositories/` |
| A pure function with no context | `utils/` |
| A helper that needs `BuildContext` | `helpers/` |
| An input rule | `validators/` |
| A shorthand on an existing type | `extensions/` |
| A closed set of values | `enums/` |
| A value that differs per environment | `config/` |
| A value that never changes | `constants/` |
| A new error type | `exceptions/` |

## Pairs that get confused

| A | B | The test |
| --- | --- | --- |
| `widgets/` | `components/` | Does it import `models/`? Then it is a component. |
| `utils/` | `helpers/` | Does it need `BuildContext`? Then it is a helper. |
| `services/` | `repositories/` | Does it return a model? Then it is a repository. |
| `config/` | `constants/` | Does it change per environment? Then it is config. |
| `providers/` | `viewmodels/` | Is it app-wide with no screen? Then it is a provider. |

## Layer-first, with feature-first where it pays

Most folders are layer-first, which keeps the architecture visible and makes the
rules easy to enforce. `onboarding/` is feature-first because it owns all three
layers and is genuinely self-contained.

For a large app, promoting a mature feature to `features/<name>/` with its own
`data/domain/presentation` is a reasonable evolution — the layer boundaries
described here are unchanged by it.

## Deleting the example slice

`Article` is the reference implementation. When you no longer need it, remove:

- `models/article.dart`
- `services/article_api_service.dart`
- `repositories/article_repository.dart`
- `viewmodels/article_list_view_model.dart`
- `views/articles/`
- `components/article_card.dart`
- the `articles` routes in `routes/`
- the `ArticleRepository` registrations in `service_locator.dart` and
  `app_providers.dart`
- the matching tests

Then `flutter analyze` will point at anything you missed.
