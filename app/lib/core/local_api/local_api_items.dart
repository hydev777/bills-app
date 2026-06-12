import 'package:app/core/local_api/local_api_itbis.dart';
import 'package:app/core/local_api/local_api_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

void registerItemRoutes(
  Router router,
  LocalApiContext context,
  SafeHandler safe,
) {
  router.get('/api/items', safe((request) => _items(request, context)));
  router.get(
    '/api/items/categories',
    safe((request) => _categories(request, context)),
  );
  router.post('/api/items', safe((request) => _createItem(request, context)));
  router.put(
    '/api/items/<id>',
    safe((request) => _updateItem(request, context)),
  );
}

Future<Response> _items(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'item', 'read');
  final params = request.url.queryParameters;
  final limit = limitValue(params['limit']);
  final offset = offsetValue(params['offset']);
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
  final total = intValue(
    context.database.read((db) {
      return db
          .select('SELECT count(*) AS c FROM items i $where', args)
          .first['c'];
    }),
  );
  final items = context.database.read((db) {
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
        .map(itemJson)
        .toList();
  });
  return jsonResponse({
    'items': items,
    'total': total,
    'limit': limit,
    'offset': offset,
  });
}

Future<Response> _categories(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'item', 'read');
  final rows = context.database.read(
    (db) => db.select('SELECT * FROM item_categories ORDER BY name ASC'),
  );
  return jsonResponse({'categories': rows.map(categoryJson).toList()});
}

Future<Response> _createItem(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'item', 'create');
  final body = await jsonBody(request);
  final name = (body['name'] as String?)?.trim();
  final unitPrice = numFromBody(body['unit_price']);
  final itbisRateId = intFromBody(body['itbis_rate_id']);
  if (name == null ||
      name.isEmpty ||
      unitPrice == null ||
      itbisRateId == null) {
    throw const HttpError(400, 'Validation error');
  }
  final categoryId = intFromBody(body['category_id']);
  final description = (body['description'] as String?)?.trim();
  final item = await context.database.transaction((db) {
    ensureItbisRateExists(db, itbisRateId);
    if (categoryId != null) {
      ensureItemCategoryExists(db, categoryId);
    }
    final duplicate = db.select(
      'SELECT id FROM items WHERE lower(name) = lower(?)',
      [name],
    );
    if (duplicate.isNotEmpty) {
      throw const HttpError(400, 'Item with this name already exists');
    }
    db.execute(
      '''
INSERT INTO items (name, description, unit_price, category_id, itbis_rate_id)
VALUES (?, ?, ?, ?, ?)
''',
      [name, description, round2(unitPrice), categoryId, itbisRateId],
    );
    return itemById(db, db.lastInsertRowId);
  });
  return jsonResponse(item, status: 201);
}

Future<Response> _updateItem(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'item', 'update');
  final id = int.tryParse(request.params['id'] ?? '');
  if (id == null) throw const HttpError(400, 'Invalid item id');
  final body = await jsonBody(request);
  final item = await context.database.transaction((db) {
    ensureItemExists(db, id);
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
        throw const HttpError(400, 'Item with this name already exists');
      }
      set('name', nextName);
    }
    if (body.containsKey('description')) {
      set('description', body['description']);
    }
    if (body.containsKey('unit_price')) {
      final unitPrice = numFromBody(body['unit_price']);
      if (unitPrice == null) throw const HttpError(400, 'Validation error');
      set('unit_price', round2(unitPrice));
    }
    if (body.containsKey('category_id')) {
      final categoryId = intFromBody(body['category_id']);
      if (categoryId != null) {
        ensureItemCategoryExists(db, categoryId);
      }
      set('category_id', categoryId);
    }
    if (body.containsKey('itbis_rate_id')) {
      final rateId = intFromBody(body['itbis_rate_id']);
      if (rateId == null) throw const HttpError(400, 'Validation error');
      ensureItbisRateExists(db, rateId);
      set('itbis_rate_id', rateId);
    }
    if (fields.isNotEmpty) {
      args.add(id);
      db.execute('UPDATE items SET ${fields.join(', ')} WHERE id = ?', args);
    }
    return itemById(db, id);
  });
  return jsonResponse(item);
}

Map<String, dynamic> categoryJson(Row row) => {
  'id': intValue(row['id']),
  'name': row['name'],
  'description': row['description'],
};

Map<String, dynamic> itemJson(Row row) => {
  'id': intValue(row['id']),
  'name': row['name'],
  'description': row['description'],
  'unitPrice': round2(doubleValue(row['unit_price'])),
  'categoryId': row['category_id'] == null
      ? null
      : intValue(row['category_id']),
  'itbisRateId': intValue(row['itbis_rate_id']),
  'category': row['category_name'] == null
      ? null
      : {'id': row['category_id'], 'name': row['category_name']},
  'itbisRate': {
    'id': intValue(row['itbis_rate_id']),
    'name': row['rate_name'],
    'percentage': round2(doubleValue(row['percentage'])),
  },
};

Map<String, dynamic> itemById(Database db, int id) {
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
  if (rows.isEmpty) throw const HttpError(404, 'Item not found');
  return itemJson(rows.first);
}

void ensureItemExists(Database db, int id) {
  if (db.select('SELECT id FROM items WHERE id = ?', [id]).isEmpty) {
    throw const HttpError(404, 'Item not found');
  }
}

void ensureItemCategoryExists(Database db, int id) {
  if (db.select('SELECT id FROM item_categories WHERE id = ?', [id]).isEmpty) {
    throw const HttpError(404, 'Category not found');
  }
}
