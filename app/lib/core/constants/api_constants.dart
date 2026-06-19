/// API constants for the embedded local API.
class ApiConstants {
  ApiConstants._();

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const String loginPath = '/api/users/login';
  static const String profilePath = '/api/users/profile';
}
