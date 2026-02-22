import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'http_logger_interceptor.dart';

/// Creates a configured Dio instance for the API.
/// Adds [HttpLoggerInterceptor] to log all requests/responses in debug.
Dio createApiClient({String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(HttpLoggerInterceptor());
  return dio;
}

/// Checks if the backend is reachable via GET /health. Returns true if OK.
Future<bool> checkBackendHealth(String baseUrl) async {
  try {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
    final response = await dio.get('/health');
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
