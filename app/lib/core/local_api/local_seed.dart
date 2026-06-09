import 'dart:math';

import 'package:app/core/local_api/local_auth.dart';
import 'package:app/core/local_api/local_database.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalSeed {
  LocalSeed(this._database, this._auth);

  final LocalDatabase _database;
  final LocalAuth _auth;

  Future<void> ensureSeeded() async {
    await _database.transaction((db) {
      _seedPrivileges(db);
      _seedBranches(db);
      _seedUsers(db);
      _seedItbisRates(db);
      _seedClients(db);
      _seedCategoriesAndItems(db);
      _seedBills(db);
    });
  }

  void _seedPrivileges(Database db) {
    final privileges = [
      ('branch.create', 'Create branches', 'branch', 'create'),
      ('branch.read', 'View branches', 'branch', 'read'),
      ('branch.update', 'Update branches', 'branch', 'update'),
      ('branch.delete', 'Delete branches', 'branch', 'delete'),
      ('user.create', 'Create users', 'user', 'create'),
      ('user.read', 'View users', 'user', 'read'),
      ('user.update', 'Update users', 'user', 'update'),
      ('user.delete', 'Delete users', 'user', 'delete'),
      ('bill.create', 'Create bills', 'bill', 'create'),
      ('bill.read', 'View bills', 'bill', 'read'),
      ('bill.update', 'Update bills', 'bill', 'update'),
      ('bill.delete', 'Delete bills', 'bill', 'delete'),
      ('item.create', 'Create items', 'item', 'create'),
      ('item.read', 'View items', 'item', 'read'),
      ('item.update', 'Update items', 'item', 'update'),
      ('item.delete', 'Delete items', 'item', 'delete'),
      ('client.create', 'Create clients', 'client', 'create'),
      ('client.read', 'View clients', 'client', 'read'),
      ('client.update', 'Update clients', 'client', 'update'),
      ('client.delete', 'Delete clients', 'client', 'delete'),
      ('privilege.grant', 'Grant privileges', 'privilege', 'grant'),
      ('privilege.revoke', 'Revoke privileges', 'privilege', 'revoke'),
      ('privilege.read', 'View privileges', 'privilege', 'read'),
      ('all', 'Access any branch', 'all', 'all'),
    ];
    for (final p in privileges) {
      db.execute(
        '''
INSERT OR IGNORE INTO privileges (name, description, resource, action)
VALUES (?, ?, ?, ?)
''',
        [p.$1, p.$2, p.$3, p.$4],
      );
    }
  }

  void _seedBranches(Database db) {
    db.execute('''
INSERT OR IGNORE INTO branches (name, code, tax_id, address, phone, email, is_active)
VALUES ('Sucursal Principal', 'MAIN', NULL, NULL, NULL, NULL, 1)
''');
  }

  void _seedUsers(Database db) {
    final users = [
      ('admin', 'admin@bills.local', 'administrador'),
      ('cajero', 'cajero@bills.local', 'cajero'),
      ('vendedor', 'vendedor@bills.local', 'user'),
    ];
    for (final user in users) {
      final exists = db.select('SELECT id FROM users WHERE username = ?', [
        user.$1,
      ]);
      if (exists.isEmpty) {
        db.execute(
          '''
INSERT INTO users (username, email, password_hash, role)
VALUES (?, ?, ?, ?)
''',
          [user.$1, user.$2, _auth.hashPassword('Password123'), user.$3],
        );
      }
    }

    final branchId = _intValue(
      db
          .select("SELECT id FROM branches WHERE code = 'MAIN' LIMIT 1")
          .first['id'],
    );
    for (final row in db.select('SELECT id, username FROM users')) {
      db.execute(
        '''
INSERT OR IGNORE INTO user_branches (user_id, branch_id, is_primary, can_login)
VALUES (?, ?, 1, 1)
''',
        [row['id'], branchId],
      );
    }

    final allPrivileges = db.select('SELECT id FROM privileges');
    final adminId = _userId(db, 'admin');
    for (final p in allPrivileges) {
      db.execute(
        'INSERT OR IGNORE INTO user_privileges (user_id, privilege_id, is_active) VALUES (?, ?, 1)',
        [adminId, p['id']],
      );
    }
    _grantByName(db, _userId(db, 'cajero'), [
      'bill.create',
      'bill.read',
      'item.read',
      'client.read',
    ]);
    _grantByName(db, _userId(db, 'vendedor'), [
      'bill.read',
      'item.read',
      'branch.read',
    ]);
  }

  void _seedItbisRates(Database db) {
    db.execute(
      "INSERT OR IGNORE INTO itbis_rates (name, percentage) VALUES ('ITBIS 18%', 18.0)",
    );
    db.execute(
      "INSERT OR IGNORE INTO itbis_rates (name, percentage) VALUES ('Exento (0%)', 0.0)",
    );
  }

  void _seedClients(Database db) {
    final clients = [
      (
        'Cliente Consumidor Final',
        'CF-001',
        null,
        'consumidor@test.local',
        '809-555-1001',
        'Calle 1 #10',
      ),
      (
        'Empresa ABC SRL',
        'RNC-131-12345678',
        '131-1234567-8',
        'abc@empresa.local',
        '809-555-2000',
        'Zona Industrial',
      ),
      (
        'Tienda La Esquina',
        null,
        null,
        'esquina@test.local',
        '809-555-3000',
        null,
      ),
    ];
    for (final c in clients) {
      final exists = c.$2 != null
          ? db.select('SELECT id FROM clients WHERE identifier = ?', [c.$2])
          : db.select('SELECT id FROM clients WHERE name = ?', [c.$1]);
      if (exists.isEmpty) {
        db.execute(
          '''
INSERT INTO clients (name, identifier, tax_id, email, phone, address)
VALUES (?, ?, ?, ?, ?, ?)
''',
          [c.$1, c.$2, c.$3, c.$4, c.$5, c.$6],
        );
      }
    }
  }

  void _seedCategoriesAndItems(Database db) {
    final branchId = _branchId(db);
    final categories = [
      ('Bebidas', 'Bebidas y refrescos'),
      ('Comestibles', 'Alimentos y snacks'),
      ('Servicios', 'Servicios facturables'),
    ];
    for (final c in categories) {
      db.execute(
        '''
INSERT OR IGNORE INTO item_categories (branch_id, name, description)
VALUES (?, ?, ?)
''',
        [branchId, c.$1, c.$2],
      );
    }

    final tax18 = _rateId(db, 18.0);
    final tax0 = _rateId(db, 0.0);
    final items = [
      ('Agua Mineral 500ml', 'Botella agua mineral', 25.0, 'Bebidas', tax0),
      ('Refresco 2L', 'Refresco sabor cola', 85.0, 'Bebidas', tax18),
      ('Sandwich Jamon y Queso', null, 150.0, 'Comestibles', tax18),
      ('Cafe Americano', 'Cafe 12 oz', 75.0, 'Bebidas', tax18),
      (
        'Consulta Tecnica 1h',
        'Servicio de consultoria',
        500.0,
        'Servicios',
        tax18,
      ),
    ];
    for (final item in items) {
      final exists = db.select(
        'SELECT id FROM items WHERE branch_id = ? AND lower(name) = lower(?)',
        [branchId, item.$1],
      );
      if (exists.isNotEmpty) continue;
      db.execute(
        '''
INSERT INTO items (branch_id, name, description, unit_price, category_id, itbis_rate_id)
VALUES (?, ?, ?, ?, ?, ?)
''',
        [
          branchId,
          item.$1,
          item.$2,
          item.$3,
          _categoryId(db, branchId, item.$4),
          item.$5,
        ],
      );
    }
  }

  void _seedBills(Database db) {
    if (db.select('SELECT id FROM bills LIMIT 1').isNotEmpty) return;
    final branchId = _branchId(db);
    final userId = _userId(db, 'admin');
    final clientRows = db.select(
      "SELECT id FROM clients WHERE identifier = 'RNC-131-12345678' LIMIT 1",
    );
    final billId = _insertBill(
      db,
      branchId: branchId,
      userId: userId,
      clientId: clientRows.isEmpty ? null : _intValue(clientRows.first['id']),
      title: 'Factura venta Empresa ABC',
      description: 'Pedido de oficina',
      status: 'draft',
    );
    _insertBillItem(db, billId, _itemId(db, branchId, 'Refresco 2L'), 2);
    _insertBillItem(db, billId, _itemId(db, branchId, 'Cafe Americano'), 1);
    _recalculateBill(db, billId);
  }

  int _insertBill(
    Database db, {
    required int branchId,
    required int userId,
    required int? clientId,
    required String title,
    required String description,
    required String status,
  }) {
    final publicId = _uuid();
    db.execute(
      '''
INSERT INTO bills (public_id, branch_id, user_id, client_id, title, description, subtotal, tax_amount, amount, status)
VALUES (?, ?, ?, ?, ?, ?, 0, 0, 0, ?)
''',
      [publicId, branchId, userId, clientId, title, description, status],
    );
    return db.lastInsertRowId;
  }

  void _insertBillItem(Database db, int billId, int itemId, int quantity) {
    final item = db.select('SELECT unit_price FROM items WHERE id = ?', [
      itemId,
    ]).first;
    final unitPrice = _doubleValue(item['unit_price']);
    db.execute(
      '''
INSERT OR IGNORE INTO bill_details (bill_id, item_id, quantity, unit_price, total_price)
VALUES (?, ?, ?, ?, ?)
''',
      [billId, itemId, quantity, unitPrice, _round2(unitPrice * quantity)],
    );
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
    var tax = 0.0;
    for (final row in rows) {
      final lineSubtotal =
          _intValue(row['quantity']) * _doubleValue(row['unit_price']);
      subtotal += lineSubtotal;
      tax += lineSubtotal * (_doubleValue(row['percentage']) / 100);
    }
    db.execute(
      'UPDATE bills SET subtotal = ?, tax_amount = ?, amount = ? WHERE id = ?',
      [_round2(subtotal), _round2(tax), _round2(subtotal + tax), billId],
    );
  }

  void _grantByName(Database db, int userId, List<String> names) {
    for (final name in names) {
      final rows = db.select('SELECT id FROM privileges WHERE name = ?', [
        name,
      ]);
      if (rows.isEmpty) continue;
      db.execute(
        'INSERT OR IGNORE INTO user_privileges (user_id, privilege_id, is_active) VALUES (?, ?, 1)',
        [userId, rows.first['id']],
      );
    }
  }
}

int _userId(Database db, String username) => _intValue(
  db.select('SELECT id FROM users WHERE username = ?', [username]).first['id'],
);

int _branchId(Database db) => _intValue(
  db.select("SELECT id FROM branches WHERE code = 'MAIN' LIMIT 1").first['id'],
);

int _categoryId(Database db, int branchId, String name) => _intValue(
  db.select(
    'SELECT id FROM item_categories WHERE branch_id = ? AND name = ? LIMIT 1',
    [branchId, name],
  ).first['id'],
);

int _rateId(Database db, double percentage) => _intValue(
  db.select('SELECT id FROM itbis_rates WHERE percentage = ? LIMIT 1', [
    percentage,
  ]).first['id'],
);

int _itemId(Database db, int branchId, String name) => _intValue(
  db.select('SELECT id FROM items WHERE branch_id = ? AND name = ? LIMIT 1', [
    branchId,
    name,
  ]).first['id'],
);

int _intValue(Object? value) =>
    value is int ? value : int.parse(value.toString());

double _doubleValue(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

double _round2(double value) => (value * 100).roundToDouble() / 100;

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
