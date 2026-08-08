import '../core/typedefs.dart';

/// A transport-agnostic HTTP response.
///
/// Repositories receive this instead of a `Response<dynamic>` from Dio, which
/// is what keeps the HTTP package out of every layer above `api/`.
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.statusCode,
    this.headers = const {},
  });

  final T data;
  final int statusCode;
  final Map<String, List<String>> headers;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Total item count for paginated endpoints, when the server sends it.
  /// `X-Total-Count` is the de-facto convention; adjust for your backend.
  int? get totalCount {
    final raw = headers['x-total-count']?.firstOrNull;
    return raw == null ? null : int.tryParse(raw);
  }

  ApiResponse<R> mapData<R>(R Function(T data) transform) => ApiResponse<R>(
    data: transform(data),
    statusCode: statusCode,
    headers: headers,
  );
}

/// A request body plus the query parameters that go with it.
///
/// Grouping them keeps method signatures short and makes a request easy to log,
/// cache-key or replay as one object.
class ApiRequest {
  const ApiRequest({this.query = const {}, this.body, this.headers = const {}});

  final Map<String, dynamic> query;
  final Object? body;
  final Map<String, String> headers;

  Json toJson() => {'query': query, 'body': body, 'headers': headers};
}
