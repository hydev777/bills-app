import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API base URL and timeouts for HTTP client.
/// Values come from .env (BASE_URL_DEV, BASE_URL_PROD) or --dart-define as fallback.
/// Dev: ENV=dev in .env → baseUrl = BASE_URL_DEV (default http://localhost:3000)
/// Prod: ENV=prod in .env or --dart-define=ENV=prod → baseUrl = BASE_URL_PROD
class ApiConstants {
  ApiConstants._();

  /// ENV from .env file, or 'prod' when --dart-define=ENV_PROD=true
  static const bool _isProdDefine = bool.fromEnvironment('ENV_PROD', defaultValue: false);
  static String get env => _isProdDefine ? 'prod' : (dotenv.env['ENV'] ?? 'dev');

  static String get baseUrl {
    final isProd = env == 'prod';
    final fromEnv = isProd
        ? dotenv.env['BASE_URL_PROD']
        : dotenv.env['BASE_URL_DEV'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const String loginPath = '/api/users/login';
  static const String profilePath = '/api/users/profile';
}
