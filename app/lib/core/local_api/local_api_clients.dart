import 'package:app/core/local_api/local_api_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

void registerClientRoutes(
  Router router,
  LocalApiContext context,
  SafeHandler safe,
) {
  router.get('/api/clients', safe((request) => _clients(request, context)));
  router.post(
    '/api/clients',
    safe((request) => _createClient(request, context)),
  );
  router.put(
    '/api/clients/<id>',
    safe((request) => _updateClient(request, context)),
  );
}

Future<Response> _clients(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'client', 'read');
  final params = request.url.queryParameters;
  final limit = limitValue(params['limit']);
  final offset = offsetValue(params['offset']);
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
  final total = intValue(
    context.database.read(
      (db) => db
          .select('SELECT count(*) AS c FROM clients $where', args)
          .first['c'],
    ),
  );
  final rows = context.database.read((db) {
    return db.select(
      'SELECT * FROM clients $where ORDER BY name ASC LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );
  });
  return jsonResponse({
    'clients': rows.map(clientJson).toList(),
    'total': total,
    'limit': limit,
    'offset': offset,
  });
}

Future<Response> _createClient(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'client', 'create');
  final body = await jsonBody(request);
  final name = (body['name'] as String?)?.trim();
  if (name == null || name.isEmpty) {
    throw const HttpError(400, 'Client name is required');
  }
  final client = await context.database.write((db) {
    db.execute(
      '''
INSERT INTO clients (name, identifier, tax_id, email, phone, address)
VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        name,
        nullableTrim(body['identifier']),
        nullableTrim(body['tax_id']),
        nullableTrim(body['email']),
        nullableTrim(body['phone']),
        nullableTrim(body['address']),
      ],
    );
    return clientJson(
      db.select('SELECT * FROM clients WHERE id = ?', [
        db.lastInsertRowId,
      ]).first,
    );
  });
  return jsonResponse(client, status: 201);
}

Future<Response> _updateClient(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'client', 'update');
  final id = int.tryParse(request.params['id'] ?? '');
  if (id == null) throw const HttpError(400, 'Invalid client id');
  final body = await jsonBody(request);
  final client = await context.database.write((db) {
    final existing = db.select('SELECT * FROM clients WHERE id = ?', [id]);
    if (existing.isEmpty) throw const HttpError(404, 'Client not found');
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
              : nullableTrim(body[entry.key]),
        );
      }
    }
    if (fields.isNotEmpty) {
      args.add(id);
      db.execute('UPDATE clients SET ${fields.join(', ')} WHERE id = ?', args);
    }
    return clientJson(
      db.select('SELECT * FROM clients WHERE id = ?', [id]).first,
    );
  });
  return jsonResponse(client);
}

Map<String, dynamic> clientJson(Row row) => {
  'id': intValue(row['id']),
  'name': row['name'],
  'identifier': row['identifier'],
  'taxId': row['tax_id'],
  'email': row['email'],
  'phone': row['phone'],
  'address': row['address'],
};
