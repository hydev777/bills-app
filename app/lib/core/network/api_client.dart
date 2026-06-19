import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../local_api/local_api_server.dart';
import 'auth_interceptor.dart';
import 'http_logger_interceptor.dart';

/// Creates a configured Dio instance for the embedded local API.
Dio createApiClient({required LocalApiServer localApiServer}) {
  final baseUrl = localApiServer.baseUrl;
  if (baseUrl == null) {
    throw const LocalApiStartupException('API local sin URL base');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  dio.interceptors.add(_LocalApiHealthInterceptor(localApiServer));
  dio.interceptors.add(AuthInterceptor());
  dio.interceptors.add(HttpLoggerInterceptor());
  return dio;
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
