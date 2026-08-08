/// Every network path, header name and query key used by the app.
///
/// Paths are relative — the host comes from `AppConfig.apiBaseUrl`, so the same
/// constants work across environments. Never inline a path at a call site.
abstract final class ApiConstants {
  // --- Headers ---
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String acceptLanguageHeader = 'Accept-Language';
  static const String requestIdHeader = 'X-Request-Id';
  static const String bearerPrefix = 'Bearer ';
  static const String jsonContentType = 'application/json';

  // --- Query keys ---
  static const String pageQuery = '_page';
  static const String limitQuery = '_limit';
  static const String searchQuery = 'q';

  // --- Example resource (replace with your own) ---
  static const String articles = '/posts';

  static String articleById(String id) => '/posts/$id';

  // --- Payments: these live on YOUR backend, never on Stripe directly ---
  static const String createPaymentIntent = '/payments/intent';
  static const String confirmPayment = '/payments/confirm';

  // --- Device registration for push notifications ---
  static const String registerDevice = '/devices';
}
