import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../local_api/local_api_server.dart';
import 'branch_interceptor.dart';
import 'http_logger_interceptor.dart';

/// Creates a configured Dio instance for the API.
/// Adds auth for protected API requests and branch scope for remote requests.
Dio createApiClient({String? baseUrl, LocalApiServer? localApiServer}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  if (localApiServer != null) {
    dio.interceptors.add(_LocalApiHealthInterceptor(localApiServer));
  }
  dio.interceptors.add(BranchInterceptor());
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

class _LocalApiHealthInterceptor extends QueuedInterceptor {
  _LocalApiHealthInterceptor(this._server);

  final LocalApiServer _server;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      await _server.ensureRunningOrRestart();
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          message: 'API local no disponible: $e',
          type: DioExceptionType.connectionError,
        ),
      );
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      try {
        await _server.ensureRunningOrRestart();
      } catch (_) {
        // Keep the original request failure. Mutating requests are never replayed.
      }
    }
    handler.next(err);
  }
}
