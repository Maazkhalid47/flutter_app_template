# test/

## Why it exists

The architecture is arranged so the valuable tests are the cheap ones. Layers
that hold logic (validators, repositories, view models, route guards) have no
Flutter dependency and test in milliseconds; only genuinely visual behaviour
needs a widget test.

## Structure

Mirrors `lib/`:

```
test/
  widget_test.dart                          core primitives smoke test
  validators/validators_test.dart           pure rules
  repositories/article_repository_test.dart error mapping, Result
  viewmodels/article_list_view_model_test.dart  state machine, pagination
  routes/route_guard_test.dart              redirect rules
  widgets/app_button_test.dart              rendering and interaction
```

## What to test at each layer

| Layer | Test | Why |
| --- | --- | --- |
| `validators/` | Every rule, valid and invalid | Pure, instant, high value |
| `repositories/` | Error mapping, decoding, caching | The contract every VM relies on |
| `viewmodels/` | State transitions, pagination, failures | Screen behaviour without a widget tree |
| `routes/` | Redirects, and that no target redirects again | Loops and leaks are expensive to find by hand |
| `widgets/` | Rendering, taps, disabled/loading states | The only thing a widget owns |
| `views/` | Rarely | Their logic already lives in a view model |

## Running

```bash
flutter test                                   # everything
flutter test test/viewmodels                   # one folder
flutter test --coverage                        # writes coverage/lcov.info
```

## Conventions

- File name: `<subject>_test.dart`, mirroring the source path.
- `group()` per method or scenario; the test name states the expected behaviour
  ("a failed loadMore keeps the pages already loaded"), not the mechanics.
- Mocks with `mocktail` (`class _MockX extends Mock implements X {}`), private
  to the file. Prefer a hand-written fake when the behaviour is one field —
  `_FakeOnboardingRepository` reads better than three `when(...)` lines.
- `registerFallbackValue` in `setUpAll` for any non-primitive `any()` argument.

## Best practices

- Test through the public API. If a test needs a private field, the class is
  probably doing too much.
- Assert the failure *type*, not the message string — messages are developer
  copy and will change.
- Every view model test needs `tearDown(() => viewModel.dispose())`, or the
  suite leaks timers between tests.
- Use `AppLogger(minimumLevel: LogLevel.fatal)` in tests to keep output clean.
- A bug fix should arrive with the test that would have caught it.
