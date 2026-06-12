import 'package:app/core/local_api/local_api_clients.dart';
import 'package:app/core/local_api/local_api_items.dart';
import 'package:app/core/local_api/local_api_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

void registerBillRoutes(
  Router router,
  LocalApiContext context,
  SafeHandler safe,
) {
  router.get('/api/bills', safe((request) => _bills(request, context)));
  router.get(
    '/api/bills/public/<publicId>',
    safe((request) => _billByPublicId(request, context)),
  );
  router.get('/api/bills/<id>', safe((request) => _billById(request, context)));
  router.post('/api/bills', safe((request) => _createBill(request, context)));
  router.post(
    '/api/bill-items',
    safe((request) => _createBillItem(request, context)),
  );
}

Future<Response> _bills(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'bill', 'read');
  final params = request.url.queryParameters;
  final limit = limitValue(params['limit']);
  final offset = offsetValue(params['offset']);
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
  final total = intValue(
    context.database.read(
      (db) => db
          .select('SELECT count(*) AS c FROM bills b $where', args)
          .first['c'],
    ),
  );
  final bills = context.database.read((db) {
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
        .map(billJson)
        .toList();
  });
  return jsonResponse({
    'bills': bills,
    'total': total,
    'limit': limit,
    'offset': offset,
  });
}

Future<Response> _billById(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'bill', 'read');
  final id = int.tryParse(request.params['id'] ?? '');
  if (id == null) throw const HttpError(400, 'Invalid bill id');
  final bill = context.database.read((db) => billByWhere(db, 'b.id = ?', [id]));
  if (bill == null) throw const HttpError(404, 'Bill not found');
  return jsonResponse(bill);
}

Future<Response> _billByPublicId(
  Request request,
  LocalApiContext context,
) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'bill', 'read');
  final publicId = request.params['publicId'];
  final bill = context.database.read(
    (db) => billByWhere(db, 'b.public_id = ?', [publicId]),
  );
  if (bill == null) throw const HttpError(404, 'Bill not found');
  return jsonResponse(bill);
}

Future<Response> _createBill(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'bill', 'create');
  final body = await jsonBody(request);
  final title = (body['title'] as String?)?.trim();
  if (title == null || title.isEmpty) {
    throw const HttpError(400, 'Validation error');
  }
  final bill = await context.database.transaction((db) {
    final clientId = intFromBody(body['client_id']);
    if (clientId != null &&
        db.select('SELECT id FROM clients WHERE id = ?', [clientId]).isEmpty) {
      throw const HttpError(404, 'Client not found');
    }
    db.execute(
      '''
INSERT INTO bills (public_id, user_id, client_id, title, description, subtotal, tax_amount, amount, status)
VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?)
''',
      [
        uuidValue(),
        claims.userId,
        clientId,
        title,
        body['description'],
        round2(numFromBody(body['amount']) ?? 0),
        body['status'] ?? 'draft',
      ],
    );
    return billByWhere(db, 'b.id = ?', [db.lastInsertRowId])!;
  });
  return jsonResponse(bill, status: 201);
}

Future<Response> _createBillItem(
  Request request,
  LocalApiContext context,
) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'bill', 'create');
  final body = await jsonBody(request);
  final billId = intFromBody(body['bill_id']);
  final itemId = intFromBody(body['item_id']);
  final quantity = intFromBody(body['quantity']) ?? 1;
  if (billId == null || itemId == null || quantity < 1) {
    throw const HttpError(400, 'Validation error');
  }
  final billItem = await context.database.transaction((db) {
    final billRows = db.select('SELECT id FROM bills WHERE id = ?', [billId]);
    if (billRows.isEmpty) throw const HttpError(404, 'Bill not found');
    final itemRows = db.select(
      '''
SELECT i.*, ir.name AS rate_name, ir.percentage
FROM items i JOIN itbis_rates ir ON ir.id = i.itbis_rate_id
WHERE i.id = ?
''',
      [itemId],
    );
    if (itemRows.isEmpty) throw const HttpError(404, 'Item not found');
    final existing = db.select(
      'SELECT id FROM bill_details WHERE bill_id = ? AND item_id = ?',
      [billId, itemId],
    );
    if (existing.isNotEmpty) {
      throw const HttpError(400, 'Item is already associated with this bill');
    }
    final unitPrice = round2(
      numFromBody(body['unit_price']) ??
          doubleValue(itemRows.first['unit_price']),
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
        round2(unitPrice * quantity),
        body['notes'],
      ],
    );
    final id = db.lastInsertRowId;
    recalculateBill(db, billId);
    return billItemJson(
      db.select('SELECT * FROM bill_details WHERE id = ?', [id]).first,
      itemRows.first,
    );
  });
  return jsonResponse(billItem, status: 201);
}

Map<String, dynamic> billJson(Row row) => {
  'id': intValue(row['id']),
  'publicId': row['public_id'],
  'title': row['title'],
  'description': row['description'],
  'subtotal': round2(doubleValue(row['subtotal'])),
  'taxAmount': round2(doubleValue(row['tax_amount'])),
  'amount': round2(doubleValue(row['amount'])),
  'status': row['status'],
  'createdAt': isoDate(row['created_at']),
  'updatedAt': isoDate(row['updated_at']),
  'user': {
    'id': intValue(row['user_id']),
    'username': row['username'],
    'email': row['user_email'],
  },
  'client': row['client_id'] == null
      ? null
      : {
          'id': intValue(row['client_id']),
          'name': row['client_name'],
          'identifier': row['client_identifier'],
          'taxId': row['client_tax_id'],
          'email': row['client_email'],
          'phone': row['client_phone'],
          'address': row['client_address'],
        },
  'billItems': const [],
};

Map<String, dynamic> billItemJson(Row row, Row item) => {
  'id': intValue(row['id']),
  'billId': intValue(row['bill_id']),
  'itemId': intValue(row['item_id']),
  'quantity': intValue(row['quantity']),
  'unitPrice': round2(doubleValue(row['unit_price'])),
  'totalPrice': round2(doubleValue(row['total_price'])),
  'notes': row['notes'],
  'item': itemJson(item),
};

Map<String, dynamic>? billByWhere(
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
  return billJson(rows.first);
}

void recalculateBill(Database db, int billId) {
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
        intValue(row['quantity']) * doubleValue(row['unit_price']);
    subtotal += lineSubtotal;
    taxAmount += lineSubtotal * (doubleValue(row['percentage']) / 100);
  }
  db.execute(
    'UPDATE bills SET subtotal = ?, tax_amount = ?, amount = ? WHERE id = ?',
    [round2(subtotal), round2(taxAmount), round2(subtotal + taxAmount), billId],
  );
}
