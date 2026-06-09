import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app/core/local_api/local_auth.dart';
import 'package:app/core/local_api/local_database.dart';
import 'package:app/core/local_api/local_seed.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

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
      _auth = auth;

  final LocalDatabase _database;
  final LocalAuth _auth;
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
      await LocalSeed(database, auth).ensureSeeded();
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
        return _json({'status': 'OK', 'service': 'bills-local-api'});
      }),
    );

    router.post('/api/users/login', _safe(_login));
    router.get('/api/users/profile', _safe(_profile));
    router.get('/api/items', _safe(_items));
    router.get('/api/items/categories', _safe(_categories));
    router.get('/api/itbis-rates', _safe(_itbisRates));
    router.post('/api/items', _safe(_createItem));
    router.put('/api/items/<id>', _safe(_updateItem));
    router.get('/api/clients', _safe(_clients));
    router.post('/api/clients', _safe(_createClient));
    router.put('/api/clients/<id>', _safe(_updateClient));
    router.get('/api/bills', _safe(_bills));
    router.get('/api/bills/public/<publicId>', _safe(_billByPublicId));
    router.get('/api/bills/<id>', _safe(_billById));
    router.post('/api/bills', _safe(_createBill));
    router.post('/api/bill-items', _safe(_createBillItem));
    router.all(
      '/<ignored|.*>',
      _safe((request) async {
        return _json({'error': 'Route not found'}, status: 404);
      }),
    );
    return router;
  }

  Handler _safe(FutureOr<Response> Function(Request request) handler) {
    return (request) async {
      try {
        return await handler(request);
      } on _HttpError catch (e) {
        return _json({'error': e.message}, status: e.status);
      } catch (e) {
        return _json({
          'error': 'Internal server error',
          'message': e.toString(),
        }, status: 500);
      }
    };
  }

  Future<Response> _login(Request request) async {
    final body = await _jsonBody(request);
    final email = (body['email'] as String?)?.trim();
    final password = body['password'] as String?;
    if (email == null || email.isEmpty || password == null) {
      throw const _HttpError(400, 'Validation error');
    }
    final rows = _database.read(
      (db) => db.select('SELECT * FROM users WHERE email = ?', [email]),
    );
    if (rows.isEmpty ||
        !_auth.verifyPassword(
          password,
          rows.first['password_hash'] as String,
        )) {
      throw const _HttpError(401, 'Invalid credentials');
    }
    final user = rows.first;
    final token = _auth.signToken(
      userId: _intValue(user['id']),
      email: user['email'] as String,
      role: user['role'] as String? ?? 'user',
    );
    return _json({
      'message': 'Login successful',
      'user': _userJson(user),
      'token': token,
    });
  }

  Future<Response> _profile(Request request) async {
    final claims = _requireAuth(request);
    final user = _userById(claims.userId);
    return _json(_userJson(user));
  }

  Future<Response> _items(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'item', 'read');
    final params = request.url.queryParameters;
    final limit = _limit(params['limit']);
    final offset = _offset(params['offset']);
    final search = params['search']?.trim();
    final category = int.tryParse(params['category'] ?? '');
    final args = <Object?>[];
    var where = '';
    if (category != null) {
      where = 'WHERE i.category_id = ?';
      args.add(category);
    }
    if (search != null && search.isNotEmpty) {
      where += where.isEmpty ? 'WHERE ' : ' AND ';
      where +=
          "(lower(i.name) LIKE ? OR lower(coalesce(i.description, '')) LIKE ?)";
      final term = '%${search.toLowerCase()}%';
      args.add(term);
      args.add(term);
    }
    final total = _intValue(
      _database.read((db) {
        return db
            .select('SELECT count(*) AS c FROM items i $where', args)
            .first['c'];
      }),
    );
    final items = _database.read((db) {
      return db
          .select(
            '''
SELECT i.*, c.name AS category_name, ir.name AS rate_name, ir.percentage
FROM items i
LEFT JOIN item_categories c ON c.id = i.category_id
JOIN itbis_rates ir ON ir.id = i.itbis_rate_id
$where
ORDER BY i.name ASC
LIMIT ? OFFSET ?
''',
            [...args, limit, offset],
          )
          .map(_itemJson)
          .toList();
    });
    return _json({
      'items': items,
      'total': total,
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> _categories(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'item', 'read');
    final rows = _database.read(
      (db) => db.select('SELECT * FROM item_categories ORDER BY name ASC'),
    );
    return _json({'categories': rows.map(_categoryJson).toList()});
  }

  Future<Response> _itbisRates(Request request) async {
    _requireAuth(request);
    final rows = _database.read(
      (db) => db.select('SELECT * FROM itbis_rates ORDER BY percentage DESC'),
    );
    return _json({'itbis_rates': rows.map(_itbisRateJson).toList()});
  }

  Future<Response> _createItem(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'item', 'create');
    final body = await _jsonBody(request);
    final name = (body['name'] as String?)?.trim();
    final unitPrice = _numFromBody(body['unit_price']);
    final itbisRateId = _intFromBody(body['itbis_rate_id']);
    if (name == null ||
        name.isEmpty ||
        unitPrice == null ||
        itbisRateId == null) {
      throw const _HttpError(400, 'Validation error');
    }
    final categoryId = _intFromBody(body['category_id']);
    final description = (body['description'] as String?)?.trim();
    final item = await _database.transaction((db) {
      _ensureRate(db, itbisRateId);
      if (categoryId != null) _ensureCategory(db, categoryId);
      final duplicate = db.select(
        'SELECT id FROM items WHERE lower(name) = lower(?)',
        [name],
      );
      if (duplicate.isNotEmpty) {
        throw const _HttpError(400, 'Item with this name already exists');
      }
      db.execute(
        '''
INSERT INTO items (name, description, unit_price, category_id, itbis_rate_id)
VALUES (?, ?, ?, ?, ?)
''',
        [name, description, _round2(unitPrice), categoryId, itbisRateId],
      );
      return _itemById(db, db.lastInsertRowId);
    });
    return _json(item, status: 201);
  }

  Future<Response> _updateItem(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'item', 'update');
    final id = int.tryParse(request.params['id'] ?? '');
    if (id == null) throw const _HttpError(400, 'Invalid item id');
    final body = await _jsonBody(request);
    final item = await _database.transaction((db) {
      _ensureItem(db, id);
      final fields = <String>[];
      final args = <Object?>[];

      void set(String column, Object? value) {
        fields.add('$column = ?');
        args.add(value);
      }

      if (body.containsKey('name')) {
        final nextName = (body['name'] as String).trim();
        final duplicate = db.select(
          'SELECT id FROM items WHERE lower(name) = lower(?) AND id != ?',
          [nextName, id],
        );
        if (duplicate.isNotEmpty) {
          throw const _HttpError(400, 'Item with this name already exists');
        }
        set('name', nextName);
      }
      if (body.containsKey('description')) {
        set('description', body['description']);
      }
      if (body.containsKey('unit_price')) {
        final unitPrice = _numFromBody(body['unit_price']);
        if (unitPrice == null) {
          throw const _HttpError(400, 'Validation error');
        }
        set('unit_price', _round2(unitPrice));
      }
      if (body.containsKey('category_id')) {
        final categoryId = _intFromBody(body['category_id']);
        if (categoryId != null) _ensureCategory(db, categoryId);
        set('category_id', categoryId);
      }
      if (body.containsKey('itbis_rate_id')) {
        final rateId = _intFromBody(body['itbis_rate_id']);
        if (rateId == null) throw const _HttpError(400, 'Validation error');
        _ensureRate(db, rateId);
        set('itbis_rate_id', rateId);
      }
      if (fields.isNotEmpty) {
        args.add(id);
        db.execute('UPDATE items SET ${fields.join(', ')} WHERE id = ?', args);
      }
      return _itemById(db, id);
    });
    return _json(item);
  }

  Future<Response> _clients(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'client', 'read');
    final params = request.url.queryParameters;
    final limit = _limit(params['limit']);
    final offset = _offset(params['offset']);
    final search = params['search']?.trim();
    final args = <Object?>[];
    var where = '';
    if (search != null && search.isNotEmpty) {
      where = '''
WHERE lower(name) LIKE ? OR lower(coalesce(identifier, '')) LIKE ?
OR lower(coalesce(tax_id, '')) LIKE ? OR lower(coalesce(email, '')) LIKE ?
''';
      final term = '%${search.toLowerCase()}%';
      args.addAll([term, term, term, term]);
    }
    final total = _intValue(
      _database.read(
        (db) => db
            .select('SELECT count(*) AS c FROM clients $where', args)
            .first['c'],
      ),
    );
    final rows = _database.read((db) {
      return db.select(
        'SELECT * FROM clients $where ORDER BY name ASC LIMIT ? OFFSET ?',
        [...args, limit, offset],
      );
    });
    return _json({
      'clients': rows.map(_clientJson).toList(),
      'total': total,
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> _createClient(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'client', 'create');
    final body = await _jsonBody(request);
    final name = (body['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      throw const _HttpError(400, 'Client name is required');
    }
    final client = await _database.write((db) {
      db.execute(
        '''
INSERT INTO clients (name, identifier, tax_id, email, phone, address)
VALUES (?, ?, ?, ?, ?, ?)
''',
        [
          name,
          _nullableTrim(body['identifier']),
          _nullableTrim(body['tax_id']),
          _nullableTrim(body['email']),
          _nullableTrim(body['phone']),
          _nullableTrim(body['address']),
        ],
      );
      return _clientJson(
        db.select('SELECT * FROM clients WHERE id = ?', [
          db.lastInsertRowId,
        ]).first,
      );
    });
    return _json(client, status: 201);
  }

  Future<Response> _updateClient(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'client', 'update');
    final id = int.tryParse(request.params['id'] ?? '');
    if (id == null) throw const _HttpError(400, 'Invalid client id');
    final body = await _jsonBody(request);
    final client = await _database.write((db) {
      final existing = db.select('SELECT * FROM clients WHERE id = ?', [id]);
      if (existing.isEmpty) throw const _HttpError(404, 'Client not found');
      final fields = <String>[];
      final args = <Object?>[];
      for (final entry in {
        'name': 'name',
        'identifier': 'identifier',
        'tax_id': 'tax_id',
        'email': 'email',
        'phone': 'phone',
        'address': 'address',
      }.entries) {
        if (body.containsKey(entry.key)) {
          fields.add('${entry.value} = ?');
          args.add(
            entry.key == 'name'
                ? (body[entry.key] as String).trim()
                : _nullableTrim(body[entry.key]),
          );
        }
      }
      if (fields.isNotEmpty) {
        args.add(id);
        db.execute(
          'UPDATE clients SET ${fields.join(', ')} WHERE id = ?',
          args,
        );
      }
      return _clientJson(
        db.select('SELECT * FROM clients WHERE id = ?', [id]).first,
      );
    });
    return _json(client);
  }

  Future<Response> _bills(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'bill', 'read');
    final params = request.url.queryParameters;
    final limit = _limit(params['limit']);
    final offset = _offset(params['offset']);
    final args = <Object?>[];
    var where = '';
    if ((params['status'] ?? '').isNotEmpty) {
      where += 'WHERE b.status = ?';
      args.add(params['status']);
    }
    if ((params['user_id'] ?? '').isNotEmpty) {
      where += where.isEmpty ? 'WHERE ' : ' AND ';
      where += 'b.user_id = ?';
      args.add(int.parse(params['user_id']!));
    }
    if ((params['client_id'] ?? '').isNotEmpty) {
      where += where.isEmpty ? 'WHERE ' : ' AND ';
      where += 'b.client_id = ?';
      args.add(int.parse(params['client_id']!));
    }
    final total = _intValue(
      _database.read(
        (db) => db
            .select('SELECT count(*) AS c FROM bills b $where', args)
            .first['c'],
      ),
    );
    final bills = _database.read((db) {
      return db
          .select(
            '''
SELECT b.*, u.username, u.email AS user_email, c.name AS client_name,
c.identifier AS client_identifier, c.tax_id AS client_tax_id, c.email AS client_email,
c.phone AS client_phone, c.address AS client_address
FROM bills b
JOIN users u ON u.id = b.user_id
LEFT JOIN clients c ON c.id = b.client_id
$where
ORDER BY b.created_at DESC
LIMIT ? OFFSET ?
''',
            [...args, limit, offset],
          )
          .map(_billJson)
          .toList();
    });
    return _json({
      'bills': bills,
      'total': total,
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> _billById(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'bill', 'read');
    final id = int.tryParse(request.params['id'] ?? '');
    if (id == null) throw const _HttpError(400, 'Invalid bill id');
    final bill = _database.read((db) => _billByWhere(db, 'b.id = ?', [id]));
    if (bill == null) throw const _HttpError(404, 'Bill not found');
    return _json(bill);
  }

  Future<Response> _billByPublicId(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'bill', 'read');
    final publicId = request.params['publicId'];
    final bill = _database.read(
      (db) => _billByWhere(db, 'b.public_id = ?', [publicId]),
    );
    if (bill == null) throw const _HttpError(404, 'Bill not found');
    return _json(bill);
  }

  Future<Response> _createBill(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'bill', 'create');
    final body = await _jsonBody(request);
    final title = (body['title'] as String?)?.trim();
    if (title == null || title.isEmpty) {
      throw const _HttpError(400, 'Validation error');
    }
    final bill = await _database.transaction((db) {
      final clientId = _intFromBody(body['client_id']);
      if (clientId != null &&
          db.select('SELECT id FROM clients WHERE id = ?', [
            clientId,
          ]).isEmpty) {
        throw const _HttpError(404, 'Client not found');
      }
      db.execute(
        '''
INSERT INTO bills (public_id, user_id, client_id, title, description, subtotal, tax_amount, amount, status)
VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?)
''',
        [
          _uuid(),
          claims.userId,
          clientId,
          title,
          body['description'],
          _round2(_numFromBody(body['amount']) ?? 0),
          body['status'] ?? 'draft',
        ],
      );
      return _billByWhere(db, 'b.id = ?', [db.lastInsertRowId])!;
    });
    return _json(bill, status: 201);
  }

  Future<Response> _createBillItem(Request request) async {
    final claims = _requireAuth(request);
    _requirePrivilege(claims.userId, claims.role, 'bill', 'create');
    final body = await _jsonBody(request);
    final billId = _intFromBody(body['bill_id']);
    final itemId = _intFromBody(body['item_id']);
    final quantity = _intFromBody(body['quantity']) ?? 1;
    if (billId == null || itemId == null || quantity < 1) {
      throw const _HttpError(400, 'Validation error');
    }
    final billItem = await _database.transaction((db) {
      final billRows = db.select('SELECT id FROM bills WHERE id = ?', [billId]);
      if (billRows.isEmpty) throw const _HttpError(404, 'Bill not found');
      final itemRows = db.select(
        '''
SELECT i.*, ir.name AS rate_name, ir.percentage
FROM items i JOIN itbis_rates ir ON ir.id = i.itbis_rate_id
WHERE i.id = ?
''',
        [itemId],
      );
      if (itemRows.isEmpty) throw const _HttpError(404, 'Item not found');
      final existing = db.select(
        'SELECT id FROM bill_details WHERE bill_id = ? AND item_id = ?',
        [billId, itemId],
      );
      if (existing.isNotEmpty) {
        throw const _HttpError(
          400,
          'Item is already associated with this bill',
        );
      }
      final unitPrice = _round2(
        _numFromBody(body['unit_price']) ??
            _doubleValue(itemRows.first['unit_price']),
      );
      db.execute(
        '''
INSERT INTO bill_details (bill_id, item_id, quantity, unit_price, total_price, notes)
VALUES (?, ?, ?, ?, ?, ?)
''',
        [
          billId,
          itemId,
          quantity,
          unitPrice,
          _round2(unitPrice * quantity),
          body['notes'],
        ],
      );
      final id = db.lastInsertRowId;
      _recalculateBill(db, billId);
      return _billItemJson(
        db.select('SELECT * FROM bill_details WHERE id = ?', [id]).first,
        itemRows.first,
      );
    });
    return _json(billItem, status: 201);
  }

  LocalTokenClaims _requireAuth(Request request) {
    final header = request.headers[HttpHeaders.authorizationHeader];
    final token = header != null && header.startsWith('Bearer ')
        ? header.substring(7)
        : null;
    if (token == null) throw const _HttpError(401, 'No token provided');
    final claims = _auth.verifyToken(token);
    if (claims == null) throw const _HttpError(401, 'Invalid token');
    _userById(claims.userId);
    return claims;
  }

  void _requirePrivilege(
    int userId,
    String role,
    String resource,
    String action,
  ) {
    if (!_hasPrivilege(userId, role, resource, action)) {
      throw _HttpError(
        403,
        'Insufficient privileges. Required: $resource.$action',
      );
    }
  }

  bool _hasPrivilege(int userId, String role, String resource, String action) {
    if (role.toLowerCase() == 'administrador') return true;
    return _database.read((db) {
      final rows = db.select(
        '''
SELECT up.id FROM user_privileges up
JOIN privileges p ON p.id = up.privilege_id
WHERE up.user_id = ? AND up.is_active = 1 AND p.is_active = 1
AND p.resource = ? AND p.action = ?
AND (up.expires_at IS NULL OR up.expires_at > CURRENT_TIMESTAMP)
LIMIT 1
''',
        [userId, resource, action],
      );
      return rows.isNotEmpty;
    });
  }

  Row _userById(int userId) {
    final rows = _database.read(
      (db) => db.select('SELECT * FROM users WHERE id = ?', [userId]),
    );
    if (rows.isEmpty) throw const _HttpError(401, 'User not found');
    return rows.first;
  }
}

Future<Map<String, dynamic>> _jsonBody(Request request) async {
  final raw = await request.readAsString();
  if (raw.isEmpty) return <String, dynamic>{};
  return jsonDecode(raw) as Map<String, dynamic>;
}

Response _json(Object value, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(value),
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  );
}

Map<String, dynamic> _userJson(Row row) => {
  'id': _intValue(row['id']),
  'username': row['username'],
  'email': row['email'],
  'role': row['role'],
};

Map<String, dynamic> _categoryJson(Row row) => {
  'id': _intValue(row['id']),
  'name': row['name'],
  'description': row['description'],
};

Map<String, dynamic> _itbisRateJson(Row row) => {
  'id': _intValue(row['id']),
  'name': row['name'],
  'percentage': _round2(_doubleValue(row['percentage'])),
};

Map<String, dynamic> _itemJson(Row row) => {
  'id': _intValue(row['id']),
  'name': row['name'],
  'description': row['description'],
  'unitPrice': _round2(_doubleValue(row['unit_price'])),
  'categoryId': row['category_id'] == null
      ? null
      : _intValue(row['category_id']),
  'itbisRateId': _intValue(row['itbis_rate_id']),
  'category': row['category_name'] == null
      ? null
      : {'id': row['category_id'], 'name': row['category_name']},
  'itbisRate': {
    'id': _intValue(row['itbis_rate_id']),
    'name': row['rate_name'],
    'percentage': _round2(_doubleValue(row['percentage'])),
  },
};

Map<String, dynamic> _clientJson(Row row) => {
  'id': _intValue(row['id']),
  'name': row['name'],
  'identifier': row['identifier'],
  'taxId': row['tax_id'],
  'email': row['email'],
  'phone': row['phone'],
  'address': row['address'],
};

Map<String, dynamic> _billJson(Row row) => {
  'id': _intValue(row['id']),
  'publicId': row['public_id'],
  'title': row['title'],
  'description': row['description'],
  'subtotal': _round2(_doubleValue(row['subtotal'])),
  'taxAmount': _round2(_doubleValue(row['tax_amount'])),
  'amount': _round2(_doubleValue(row['amount'])),
  'status': row['status'],
  'createdAt': _isoDate(row['created_at']),
  'updatedAt': _isoDate(row['updated_at']),
  'user': {
    'id': _intValue(row['user_id']),
    'username': row['username'],
    'email': row['user_email'],
  },
  'client': row['client_id'] == null
      ? null
      : {
          'id': _intValue(row['client_id']),
          'name': row['client_name'],
          'identifier': row['client_identifier'],
          'taxId': row['client_tax_id'],
          'email': row['client_email'],
          'phone': row['client_phone'],
          'address': row['client_address'],
        },
  'billItems': const [],
};

Map<String, dynamic> _billItemJson(Row row, Row item) => {
  'id': _intValue(row['id']),
  'billId': _intValue(row['bill_id']),
  'itemId': _intValue(row['item_id']),
  'quantity': _intValue(row['quantity']),
  'unitPrice': _round2(_doubleValue(row['unit_price'])),
  'totalPrice': _round2(_doubleValue(row['total_price'])),
  'notes': row['notes'],
  'item': _itemJson(item),
};

Map<String, dynamic>? _billByWhere(
  Database db,
  String condition,
  List<Object?> args,
) {
  final rows = db.select('''
SELECT b.*, u.username, u.email AS user_email, c.name AS client_name,
c.identifier AS client_identifier, c.tax_id AS client_tax_id, c.email AS client_email,
c.phone AS client_phone, c.address AS client_address
FROM bills b
JOIN users u ON u.id = b.user_id
LEFT JOIN clients c ON c.id = b.client_id
WHERE $condition
LIMIT 1
''', args);
  if (rows.isEmpty) return null;
  return _billJson(rows.first);
}

Map<String, dynamic> _itemById(Database db, int id) {
  final rows = db.select(
    '''
SELECT i.*, c.name AS category_name, ir.name AS rate_name, ir.percentage
FROM items i
LEFT JOIN item_categories c ON c.id = i.category_id
JOIN itbis_rates ir ON ir.id = i.itbis_rate_id
WHERE i.id = ?
LIMIT 1
''',
    [id],
  );
  if (rows.isEmpty) throw const _HttpError(404, 'Item not found');
  return _itemJson(rows.first);
}

void _ensureItem(Database db, int id) {
  if (db.select('SELECT id FROM items WHERE id = ?', [id]).isEmpty) {
    throw const _HttpError(404, 'Item not found');
  }
}

void _ensureCategory(Database db, int id) {
  if (db.select('SELECT id FROM item_categories WHERE id = ?', [id]).isEmpty) {
    throw const _HttpError(404, 'Category not found');
  }
}

void _ensureRate(Database db, int id) {
  if (db.select('SELECT id FROM itbis_rates WHERE id = ?', [id]).isEmpty) {
    throw const _HttpError(404, 'ITBIS rate not found');
  }
}

void _recalculateBill(Database db, int billId) {
  final rows = db.select(
    '''
SELECT bd.quantity, bd.unit_price, ir.percentage
FROM bill_details bd
JOIN items i ON i.id = bd.item_id
JOIN itbis_rates ir ON ir.id = i.itbis_rate_id
WHERE bd.bill_id = ?
''',
    [billId],
  );
  var subtotal = 0.0;
  var taxAmount = 0.0;
  for (final row in rows) {
    final lineSubtotal =
        _intValue(row['quantity']) * _doubleValue(row['unit_price']);
    subtotal += lineSubtotal;
    taxAmount += lineSubtotal * (_doubleValue(row['percentage']) / 100);
  }
  db.execute(
    'UPDATE bills SET subtotal = ?, tax_amount = ?, amount = ? WHERE id = ?',
    [
      _round2(subtotal),
      _round2(taxAmount),
      _round2(subtotal + taxAmount),
      billId,
    ],
  );
}

int _limit(String? raw) => min(100, max(1, int.tryParse(raw ?? '') ?? 50));

int _offset(String? raw) => max(0, int.tryParse(raw ?? '') ?? 0);

int? _intFromBody(Object? value) {
  if (value == null || value == '') return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _numFromBody(Object? value) {
  if (value == null || value == '') return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _nullableTrim(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _intValue(Object? value) =>
    value is int ? value : int.parse(value.toString());

double _doubleValue(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

double _round2(double value) => (value * 100).roundToDouble() / 100;

String _isoDate(Object? value) {
  final text = value?.toString() ?? DateTime.now().toIso8601String();
  if (text.contains('T')) return text;
  return DateTime.tryParse(text)?.toIso8601String() ??
      DateTime.now().toIso8601String();
}

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class _HttpError implements Exception {
  const _HttpError(this.status, this.message);

  final int status;
  final String message;
}
