# repositories/

## Why it exists

The boundary between "data" and "the app". A repository is the only place that
knows where data comes from — network, cache, or a local store — and it is the
place where thrown exceptions stop and typed `Result`s begin.

Everything above it (view models, views) is written against domain types only,
which is what makes the backend replaceable and the UI testable.

## What belongs here

- `base_repository.dart` — `guard()` (error mapping) and `cachedFetch()`
  (cache-then-network with offline fallback).
- One file per aggregate: `article_repository.dart`, `order_repository.dart`.

`auth/auth_repository.dart` and `onboarding/onboarding_repository.dart` live in
their feature folders but follow exactly these rules.

## What does NOT belong here

- HTTP paths and SDK calls (→ `services/`).
- UI state such as "is the button busy" (→ `viewmodels/`).
- Widget or `BuildContext` references — a repository must never import Flutter.

## Naming conventions

- Interface: `<Aggregate>Repository` (`abstract interface class`).
- Implementation: `<Aggregate>RepositoryImpl extends BaseRepository`.
- Methods read as intent: `fetchArticles`, `createArticle`, `deleteArticle`.
- Cache keys are namespaced: `articles:list:1:20`, `articles:detail:42`.

## Example usage

```dart
abstract interface class OrderRepository {
  AsyncResult<List<Order>> fetchOrders();
}

class OrderRepositoryImpl extends BaseRepository implements OrderRepository {
  const OrderRepositoryImpl({
    required OrderApiService service,
    required super.logger,
    super.cache,
  }) : _service = service;

  final OrderApiService _service;

  @override
  AsyncResult<List<Order>> fetchOrders() => guard(() async {
        final response = await _service.fetchOrders();
        return response.data.map(Order.fromJson).toList();
      }, context: 'fetchOrders');
}
```

## Best practices

- Never write `try/catch` in a repository method — wrap the body in `guard()`
  so every failure is mapped the same way.
- Return `Result`, never `null`, to signal failure. `null` cannot say why.
- Invalidate the cache namespace after any mutation, or the next read serves
  the value you just changed.
- Depend on interfaces (`ApiClient`, not `Dio`) so tests need no HTTP.
- Repositories are where you unit-test error mapping — see
  `test/repositories/article_repository_test.dart`.
