import 'package:dio/dio.dart';

import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/injection.dart';

/// Path prefixes that require X-Branch-Id header (branch-scoped API).
const _branchScopedPaths = [
  '/api/items',
  '/api/bills',
  '/api/clients',
  '/api/branches',
];

/// Adds Authorization (Bearer) and X-Branch-Id for branch-scoped paths.
/// Uses [QueuedInterceptor] so async session/branch logic runs before the request is sent.
class BranchInterceptor extends QueuedInterceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _injectAuthAndBranch(options, handler);
  }

  Future<void> _injectAuthAndBranch(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final session = await sl<AuthLocalDataSource>().getSession();
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.token}';
        final needsBranch =
            _branchScopedPaths.any((p) => options.path.startsWith(p));
        if (needsBranch) {
          int? branchId = session.selectedBranchId;
          if (branchId == null &&
              session.accessibleBranches.isNotEmpty) {
            branchId = session.accessibleBranches.first.id;
            final updatedSession = Session(
              token: session.token,
              user: session.user,
              accessibleBranches: session.accessibleBranches,
              selectedBranchId: branchId,
            );
            await sl<AuthLocalDataSource>().saveSession(updatedSession);
          }
          if (branchId != null) {
            options.headers['X-Branch-Id'] = branchId.toString();
          }
        }
      }
    } catch (_) {
      // ignore: session not available
    }
    handler.next(options);
  }
}
