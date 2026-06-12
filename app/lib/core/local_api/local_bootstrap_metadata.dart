import 'package:app/core/local_api/local_database.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalBootstrapMetadata {
  LocalBootstrapMetadata(this._database);

  final LocalDatabase _database;

  Future<void> ensureInitialized() async {
    await _database.transaction((db) {
      _seedPrivileges(db);
      _seedItbisRates(db);
      _seedCategories(db);
    });
  }

  void _seedPrivileges(Database db) {
    for (final privilege in _privileges) {
      db.execute(
        '''
INSERT OR IGNORE INTO privileges (name, description, resource, action)
VALUES (?, ?, ?, ?)
''',
        [privilege.$1, privilege.$2, privilege.$3, privilege.$4],
      );
    }
  }

  void _seedItbisRates(Database db) {
    for (final rate in _itbisRates) {
      db.execute(
        'INSERT OR IGNORE INTO itbis_rates (name, percentage) VALUES (?, ?)',
        [rate.$1, rate.$2],
      );
    }
  }

  void _seedCategories(Database db) {
    for (final category in _categories) {
      db.execute(
        '''
INSERT OR IGNORE INTO item_categories (name, description)
VALUES (?, ?)
''',
        [category.$1, category.$2],
      );
    }
  }
}

const _privileges = [
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
];

const _itbisRates = [('ITBIS 18%', 18.0), ('Exento (0%)', 0.0)];

const _categories = [
  ('Bebidas', 'Bebidas y refrescos'),
  ('Comestibles', 'Alimentos y snacks'),
  ('Servicios', 'Servicios facturables'),
];
