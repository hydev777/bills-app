import 'dart:async';
import 'dart:io';

import 'package:app/core/local_api/local_api_bills.dart';
import 'package:app/core/local_api/local_bootstrap_metadata.dart';
import 'package:app/core/local_api/local_api_clients.dart';
import 'package:app/core/local_api/local_api_items.dart';
import 'package:app/core/local_api/local_api_itbis.dart';
import 'package:app/core/local_api/local_api_reports.dart';
import 'package:app/core/local_api/local_api_shared.dart';
import 'package:app/core/local_api/local_api_users.dart';
import 'package:app/core/local_api/local_auth.dart';
import 'package:app/core/local_api/local_database.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class LocalApiStartupException implements Exception {
  const LocalApiStartupException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message: $cause';
}

class LocalApiServer {
  LocalApiServer._({required LocalDatabase database, required LocalAuth auth})
    : _database = database,
      _auth = auth,
      _context = LocalApiContext(database: database, auth: auth);

  final LocalDatabase _database;
  final LocalAuth _auth;
  final LocalApiContext _context;
  HttpServer? _server;
  Future<void>? _restartFuture;

  String? get baseUrl {
    final server = _server;
    if (server == null) return null;
    return 'http://127.0.0.1:${server.port}';
  }

  static Future<LocalApiServer> startPersistent() async {
    try {
      final auth = await LocalAuth.create();
      final database = await LocalDatabase.openPersistent();
      await LocalBootstrapMetadata(database).ensureInitialized();
      final server = LocalApiServer._(database: database, auth: auth);
      await server.start();
      await server.ensureHealthy();
      return server;
    } catch (e) {
      throw LocalApiStartupException('No se pudo iniciar la API local', e);
    }
  }

  Future<void> start() async {
    if (_server != null) return;
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_router.call);
    _server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4,
      0,
      shared: false,
    );
  }

  Future<void> ensureHealthy() async {
    final url = baseUrl;
    if (url == null) {
      throw const LocalApiStartupException('API local no iniciada');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client.getUrl(Uri.parse('$url/health'));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw LocalApiStartupException(
          'Health check local fallo: ${response.statusCode}',
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> ensureRunningOrRestart() {
    if (_restartFuture != null) return _restartFuture!;
    _restartFuture = _ensureRunningOrRestart().whenComplete(() {
      _restartFuture = null;
    });
    return _restartFuture!;
  }

  Future<void> _ensureRunningOrRestart() async {
    try {
      await ensureHealthy();
      return;
    } catch (_) {
      await close(forceAfterTimeout: true);
      await start();
      await ensureHealthy();
    }
  }

  Future<void> close({bool forceAfterTimeout = false}) async {
    final server = _server;
    _server = null;
    if (server == null) return;
    try {
      await server.close().timeout(const Duration(seconds: 2));
    } on TimeoutException {
      if (forceAfterTimeout) {
        await server.close(force: true);
      }
    }
  }

  Future<void> dispose() async {
    await close(forceAfterTimeout: true);
    _database.close();
  }

  Router get _router {
    final router = Router();
    router.get(
      '/health',
      _safe((request) async {
        return jsonResponse({'status': 'OK', 'service': 'bills-local-api'});
      }),
    );

    registerUserRoutes(router, _context, _safe);
    registerItemRoutes(router, _context, _safe);
    registerItbisRoutes(router, _context, _safe);
    registerClientRoutes(router, _context, _safe);
    registerBillRoutes(router, _context, _safe);
    registerReportRoutes(router, _context, _safe);
    router.all(
      '/<ignored|.*>',
      _safe((request) async {
        return jsonResponse({'error': 'Route not found'}, status: 404);
      }),
    );
    return router;
  }

  Handler _safe(Future<Response> Function(Request request) handler) {
    return (request) async {
      try {
        return await handler(request);
      } on HttpError catch (e) {
        return jsonResponse({'error': e.message}, status: e.status);
      } catch (e) {
        return jsonResponse({
          'error': 'Internal server error',
          'message': e.toString(),
        }, status: 500);
      }
    };
  }
}
