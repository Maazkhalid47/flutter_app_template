# api/

## Why it exists

The HTTP abstraction. `ApiClient` is an interface; `DioApiClient` is the only
file in the app that calls Dio's request API. Swapping the HTTP package, or
faking it in a test, touches this folder and nothing else.

## What belongs here

| File | Purpose |
| --- | --- |
| `api_client.dart` | The interface every network call goes through |
| `dio_api_client.dart` | The Dio implementation |
| `api_response.dart` | `ApiResponse<T>`, `ApiRequest` — transport-agnostic |
| `cancellation_token.dart` | App-owned cancellation, bridged to Dio internally |

Interceptors live in `network/interceptors/`, because they are transport
policy (auth, retry, connectivity) rather than the calling surface.

## What does NOT belong here

- Endpoint paths (→ `constants/api_constants.dart`).
- Decoding into models (→ `repositories/`).
- Error handling. This layer throws; the repository maps.

## Naming conventions

- Methods say what comes back: `requestJson`, `requestJsonList`, `requestBytes`.
- The HTTP verb is a parameter (`HttpMethod.get`), not part of the name.

## Example usage

```dart
final response = await _client.requestJsonList(
  HttpMethod.get,
  ApiConstants.articles,
  query: {ApiConstants.pageQuery: 1},
  cancellationToken: token,
);
final articles = response.data.map(Article.fromJson).toList();
```

Cancelling:

```dart
final token = CancellationToken();
// …later, e.g. in dispose() or when a new search supersedes this one
token.cancel();
```

## Best practices

- Never import `package:dio/dio.dart` outside `api/` and
  `network/interceptors/`. A `CancelToken` or `DioException` in a view model
  means the abstraction has already leaked.
- Attach a `CancellationToken` to anything a user can navigate away from.
- Interceptor order is decided in the service locator, and it matters:
  connectivity → auth → retry → logging.
- `requestJson` treats an empty body as `{}`, so a `204 No Content` is a
  success rather than a parse error.
