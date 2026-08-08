/// Path constants for the custom backend. Keep [ApiClient]'s baseUrl (from
/// .env) free of trailing paths and build full routes from here.
class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const refreshToken = '/auth/refresh';
  static const profile = '/users/me';
}
