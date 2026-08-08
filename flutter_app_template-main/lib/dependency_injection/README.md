# dependency_injection/

## Why it exists

One composition root. Every dependency in the app is constructed in
`service_locator.dart` and nowhere else, so the entire object graph — including
interceptor order and which implementation is active — is reviewable in a single
file.

## The rule that makes this work

**Classes receive dependencies through their constructor. They never call
`getIt<T>()` internally.**

Only three places resolve from the locator: `bootstrap.dart`, the root provider
list, and a screen creating its own view model. A repository that reaches into
`getIt` is untestable, because there is no seam to substitute a fake.

## Registration styles

| Style | Use for | Example |
| --- | --- | --- |
| `registerSingleton` | Already built, needed immediately | `AppConfig`, `AppLogger` |
| `registerLazySingleton` | One instance, built on first use | Repositories, services |
| `registerFactory` | Fresh instance per call | Screen view models |

## Example usage

Registering:

```dart
getIt.registerLazySingleton<OrderRepository>(
  () => OrderRepositoryImpl(
    service: getIt<OrderApiService>(),
    cache: getIt<CacheManager>(),
    logger: getIt<AppLogger>(),
  ),
);
```

Resolving — only at a composition point:

```dart
Provider<OrderRepository>(create: (_) => getIt<OrderRepository>()),
```

In a test, no locator at all:

```dart
final repository = OrderRepositoryImpl(
  service: MockOrderApiService(),
  logger: AppLogger(minimumLevel: LogLevel.fatal),
);
```

## Best practices

- Register the **interface**, not the implementation:
  `registerLazySingleton<AuthRepository>(() => SupabaseAuthRepository(...))`.
  That one line is what makes the backend swappable.
- Order matters where it is written that way — interceptors are attached last
  because they need `TokenStorage` and `AuthRepository`.
- Conditional registration is fine and useful: unconfigured Supabase gets
  `UnavailableAuthRepository` instead of a crash.
- Use `DiTokens` for named instances rather than raw strings.
- Anything holding a subscription implements `Disposable` and is torn down in
  `ServiceLocator.reset()`.
