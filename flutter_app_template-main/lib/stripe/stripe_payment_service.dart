import '../api/api_client.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../core/result.dart';
import '../core/typedefs.dart';
import '../enums/http_method.dart';
import '../enums/payment_status.dart';
import '../exceptions/app_exception.dart';
import '../exceptions/exception_mapper.dart';
import '../services/analytics_service.dart';
import '../utils/logger.dart';
import 'payment_intent.dart';
import 'payment_service.dart';

/// Stripe integration, backend-first.
///
/// ## Why there is no `flutter_stripe` dependency here
///
/// The architecture — intent created server-side, client secret returned,
/// client confirms — is identical whether the confirmation UI is Stripe's
/// native `PaymentSheet` or a hosted Checkout page opened in a browser. This
/// template ships the part that never changes and leaves the UI choice to you,
/// so the project builds on every platform out of the box with no Android
/// Kotlin/Gradle or iOS pod configuration required on day one.
///
/// To add the native sheet:
/// 1. `flutter pub add flutter_stripe`, then follow its Android/iOS setup.
/// 2. In [initialize], set `Stripe.publishableKey` from [AppConfig].
/// 3. In [confirmPayment], replace the `_confirmOnBackend` call with
///    `Stripe.instance.initPaymentSheet(...)` + `presentPaymentSheet()`.
///
/// Everything above this class — view models, views, the [PaymentService]
/// interface — stays untouched. That is the point of the abstraction.
class StripePaymentService implements PaymentService {
  StripePaymentService({
    required ApiClient apiClient,
    required AppConfig config,
    required AnalyticsService analytics,
    required AppLogger logger,
  }) : _apiClient = apiClient,
       _config = config,
       _analytics = analytics,
       _logger = logger;

  final ApiClient _apiClient;
  final AppConfig _config;
  final AnalyticsService _analytics;
  final AppLogger _logger;

  bool _initialized = false;

  @override
  bool get isAvailable => _initialized && _config.isStripeConfigured;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (!_config.isStripeConfigured) {
      _logger.warning(
        'Stripe is not configured; payments are disabled. '
        'Pass --dart-define=STRIPE_PUBLISHABLE_KEY=...',
      );
      return;
    }
    // With flutter_stripe added, this is where the publishable key and the
    // Apple Pay merchant identifier are handed to the SDK.
    _initialized = true;
    _logger.info('Payment service ready.');
  }

  @override
  AsyncResult<PaymentIntentModel> createPaymentIntent(
    PaymentRequest request,
  ) async {
    final unavailable = _unavailableFailure<PaymentIntentModel>();
    if (unavailable != null) return unavailable;

    return _guard(() async {
      await _analytics.logEvent(
        AnalyticsEvent.paymentStarted,
        parameters: {
          'currency': request.currency,
          'amount': request.amountMinorUnits,
        },
      );
      final response = await _apiClient.requestJson(
        HttpMethod.post,
        ApiConstants.createPaymentIntent,
        body: request.toJson(),
      );
      return PaymentIntentModel.fromJson(response.data);
    });
  }

  @override
  AsyncResult<PaymentIntentModel> confirmPayment(
    PaymentIntentModel intent,
  ) async {
    final unavailable = _unavailableFailure<PaymentIntentModel>();
    if (unavailable != null) return unavailable;

    final result = await _guard(() => _confirmOnBackend(intent));

    await result.when(
      success: (confirmed) => _analytics.logEvent(
        confirmed.status == PaymentStatus.succeeded
            ? AnalyticsEvent.paymentSucceeded
            : AnalyticsEvent.paymentFailed,
        parameters: {'status': confirmed.status.name},
      ),
      failure: (exception) => _analytics.logEvent(
        AnalyticsEvent.paymentFailed,
        parameters: {'code': exception.code ?? 'unknown'},
      ),
    );

    return result;
  }

  @override
  AsyncResult<PaymentIntentModel> checkout(PaymentRequest request) async {
    final created = await createPaymentIntent(request);
    return created.when(
      success: confirmPayment,
      failure: (exception) async =>
          Result<PaymentIntentModel>.failure(exception),
    );
  }

  @override
  AsyncResult<PaymentIntentModel> refreshStatus(String paymentIntentId) =>
      _guard(() async {
        final response = await _apiClient.requestJson(
          HttpMethod.get,
          '${ApiConstants.createPaymentIntent}/$paymentIntentId',
        );
        return PaymentIntentModel.fromJson(response.data);
      });

  /// Confirmation via your backend, which talks to Stripe with the secret key.
  /// Replace with the native payment sheet when you add `flutter_stripe`.
  Future<PaymentIntentModel> _confirmOnBackend(
    PaymentIntentModel intent,
  ) async {
    final response = await _apiClient.requestJson(
      HttpMethod.post,
      ApiConstants.confirmPayment,
      body: {'payment_intent_id': intent.id},
    );
    return PaymentIntentModel.fromJson(response.data);
  }

  /// Returns a typed failure when payments are switched off, so callers get a
  /// clear reason instead of a confusing network error.
  Result<T>? _unavailableFailure<T>() {
    if (isAvailable) return null;
    return const Result.failure(
      PaymentException(message: 'Payments are not configured for this build.'),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result<T>.success(await operation());
    } catch (error, stackTrace) {
      final mapped = ExceptionMapper.map(error, stackTrace);
      _logger.error('Payment failed', error: error, stackTrace: stackTrace);
      return Result<T>.failure(
        mapped is PaymentException
            ? mapped
            : PaymentException(
                message: mapped.message,
                code: mapped.code,
                cause: mapped.cause,
                stackTrace: stackTrace,
              ),
      );
    }
  }
}
