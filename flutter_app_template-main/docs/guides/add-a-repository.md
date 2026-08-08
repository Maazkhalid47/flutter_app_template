# How to add a new repository

A repository turns "a service that can throw" into "a contract that returns
`Result`". It is where caching, decoding and error mapping live.

## 1. Define the contract

Domain types only — no JSON, no HTTP, no SDK.

```dart
// lib/repositories/order_repository.dart
abstract interface class OrderRepository {
  AsyncResult<PaginatedResult<Order>> fetchOrders({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  });

  AsyncResult<Order> fetchOrder(String id);

  AsyncResult<Order> createOrder({required int totalMinorUnits});
}
```

## 2. Implement on `BaseRepository`

```dart
class OrderRepositoryImpl extends BaseRepository implements OrderRepository {
  const OrderRepositoryImpl({
    required OrderApiService service,
    required super.logger,
    super.cache,
  }) : _service = service;

  final OrderApiService _service;

  static const String _cacheNamespace = 'orders';

  @override
  AsyncResult<PaginatedResult<Order>> fetchOrders({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) =>
      cachedFetch<PaginatedResult<Order>>(
        cacheKey: '$_cacheNamespace:list:$page:$pageSize',
        forceRefresh: forceRefresh,
        fetch: () async {
          final response = await _service.fetchOrders(
            page: page,
            pageSize: pageSize,
            cancellationToken: cancellationToken,
          );
          return PaginatedResult<Order>(
            items: response.data.map(Order.fromJson).toList(),
            page: page,
            pageSize: pageSize,
            totalCount: response.totalCount,
          );
        },
        decode: (cached) => PaginatedResult<Order>(
          items: (cached! as List)
              .map((dynamic e) =>
                  Order.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
          page: page,
          pageSize: pageSize,
        ),
        encode: (value) => value.items.map((o) => o.toJson()).toList(),
      );

  @override
  AsyncResult<Order> createOrder({required int totalMinorUnits}) =>
      guard(() async {
        final response = await _service.createOrder({'total': totalMinorUnits});
        // Every cached page is now stale.
        await invalidateCache(_cacheNamespace);
        return Order.fromJson(response.data);
      }, context: 'createOrder');
}
```

## `guard` vs `cachedFetch`

| Use | When |
| --- | --- |
| `guard()` | Mutations, and reads that must not be cached |
| `cachedFetch()` | Reads that benefit from caching and offline fallback |

Never write your own `try/catch` — that is what these two exist for.

## What `cachedFetch` does for you

1. Returns a fresh cache entry without a request.
2. Otherwise fetches, and caches the result.
3. If the fetch fails **and the failure is retryable**, serves the stale entry
   rather than an error screen. That is the offline story.

A 404 does not resurrect stale data — only retryable failures do.

## Cache keys

Namespace with `:` so one call invalidates a whole family:

```
orders:list:1:20
orders:detail:42
```

```dart
await invalidateCache('orders');   // clears both
```

## 3. Register it

```dart
getIt.registerLazySingleton<OrderRepository>(
  () => OrderRepositoryImpl(
    service: getIt<OrderApiService>(),
    cache: getIt<CacheManager>(),
    logger: getIt<AppLogger>(),
  ),
);
```

Register the **interface**. That single choice is what lets you swap the
implementation later.

## 4. Test it

Repository tests are the highest-value tests in this architecture — they cover
the error-mapping contract everything above depends on. Copy
`test/repositories/article_repository_test.dart`: mock the service, assert the
`AppException` *type* for each transport failure.

## Checklist

- [ ] Interface exposes domain types only
- [ ] `extends BaseRepository implements <X>Repository`
- [ ] No `try/catch` anywhere in the file
- [ ] Cache namespaced and invalidated after mutations
- [ ] Interface registered in the service locator
- [ ] Tests for success, 404, 500 and offline
