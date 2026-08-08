import 'package:dio/dio.dart';

import '../network_info.dart';

/// Rejects requests before they leave the device when there is no connection.
///
/// Saves the caller a 30-second timeout and produces a precise error instead of
/// an ambiguous one. Deliberately checked per request rather than cached: the
/// device can lose its connection between two taps.
class ConnectivityInterceptor extends Interceptor {
  const ConnectivityInterceptor(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connected = await _networkInfo.isConnected;
    if (connected) {
      handler.next(options);
      return;
    }
    handler.reject(
      DioException.connectionError(
        requestOptions: options,
        reason: 'No network connection.',
      ),
      // `true` so the rejection surfaces to the caller as a normal DioException
      // and flows through ExceptionMapper like any other failure.
      true,
    );
  }
}
