# services/

## Why it exists

Services own the mechanics of talking to the outside world: which endpoint, which
SDK call, which payload shape. They know *how*, never *why*.

## services/ vs repositories/

| | `services/` | `repositories/` |
| --- | --- | --- |
| Knows about | HTTP paths, SDKs, JSON | Domain models |
| Returns | `ApiResponse<Json>` | `Result<Article>` |
| On failure | Throws | Converts to `Result.failure` |
| Caching | Never | Yes (`cachedFetch`) |
| Depended on by | Repositories | View models |

A view model that imports a service directly has skipped a layer.

## What belongs here

- `analytics_service.dart` — vendor-agnostic analytics/crash interface plus the
  no-op default.
- `article_api_service.dart` — example endpoint group.

Some services are large enough to own a folder: `supabase/`, `stripe/`,
`notifications/`. They follow the same rules.

## Naming conventions

- `<Domain>ApiService` for REST endpoint groups.
- `<Capability>Service` for a capability behind an interface
  (`AnalyticsService`, `PaymentService`, `PermissionService`).
- Interface and implementation in the same file when small; separate files when
  the implementation is substantial.

## Example usage

```dart
class OrderApiService {
  const OrderApiService(this._client);
  final ApiClient _client;

  Future<ApiResponse<JsonList>> fetchOrders({required int page}) =>
      _client.requestJsonList(
        HttpMethod.get,
        ApiConstants.orders,
        query: {ApiConstants.pageQuery: page},
      );
}
```

## Best practices

- Define every capability as an `abstract interface class` with at least a
  no-op implementation. That is what makes analytics, payments and push
  optional at build time instead of crashing when unconfigured.
- Do not catch exceptions in a service. Let them reach the repository, which
  maps them once via `ExceptionMapper`.
- No decoding into models here — a service returns JSON, the repository decides
  what it means.
- Register services in `dependency_injection/service_locator.dart`, never
  construct one inside a widget.
