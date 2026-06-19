import 'package:dio/dio.dart';

import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/injection.dart';

/// Adds Authorization (Bearer) for protected local API requests.
/// Uses [QueuedInterceptor] so async session lookup runs before requests are sent.
class AuthInterceptor extends QueuedInterceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final session = await sl<AuthLocalDataSource>().getSession();
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.token}';
      }
    } catch (_) {
      // Session may be unavailable during bootstrap/login.
    }
    handler.next(options);
  }
}
