# How to add a new API endpoint

Adding `GET /orders` and `POST /orders`, end to end.

## 1. Add the paths

`lib/constants/api_constants.dart`:

```dart
static const String orders = '/orders';

static String orderById(String id) => '/orders/$id';
```

Never inline a path at a call site.

## 2. Add the model

`lib/models/order.dart`:

```dart
class Order {
  const Order({required this.id, required this.totalMinorUnits});

  factory Order.fromJson(Json json) => Order(
        // Defensive: survives a backend changing int → string.
        id: json['id'].toString(),
        totalMinorUnits: (json['total'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final int totalMinorUnits;

  Json toJson() => {'id': id, 'total': totalMinorUnits};
}
```

Money is always in **minor units** (cents) as an `int`. Doubles for currency
produce rounding bugs you will find in production.

## 3. Add the service

`lib/services/order_api_service.dart`:

```dart
class OrderApiService {
  const OrderApiService(this._client);

  final ApiClient _client;

  Future<ApiResponse<JsonList>> fetchOrders({
    required int page,
    required int pageSize,
    CancellationToken? cancellationToken,
  }) =>
      _client.requestJsonList(
        HttpMethod.get,
        ApiConstants.orders,
        query: {
          ApiConstants.pageQuery: page,
          ApiConstants.limitQuery: pageSize,
        },
        cancellationToken: cancellationToken,
      );

  Future<ApiResponse<Json>> createOrder(Json payload) =>
      _client.requestJson(HttpMethod.post, ApiConstants.orders, body: payload);
}
```

A service does not catch, decode, or cache. It only knows how to call.

## 4. Add the repository

See [add-a-repository.md](add-a-repository.md).

## 5. Register both

`lib/dependency_injection/service_locator.dart`:

```dart
getIt
  ..registerLazySingleton<OrderApiService>(
    () => OrderApiService(getIt<ApiClient>()),
  )
  ..registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(
      service: getIt<OrderApiService>(),
      cache: getIt<CacheManager>(),
      logger: logger,
    ),
  );
```

## What you do NOT have to do

The interceptors already handle, for every request:

- attaching the bearer token, and refreshing it once on a 401,
- rejecting the call instantly when the device is offline,
- retrying transient failures with backoff (idempotent verbs only),
- logging with timings and credential redaction.

## Response shapes

| Shape | Method |
| --- | --- |
| JSON object | `requestJson` |
| JSON array | `requestJsonList` |
| Bytes (file, image) | `requestBytes` |
| Multipart upload | `upload` |

Pagination: if the server sends `X-Total-Count`, `ApiResponse.totalCount` picks
it up and `PaginatedResult.hasMore` becomes exact.

## Testing

Test the repository with a mocked service — that covers decoding and error
mapping, which is where the bugs are. There is no value in testing the service
itself, since it contains no branches.
