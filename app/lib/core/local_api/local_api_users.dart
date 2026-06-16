import 'package:app/core/local_api/local_api_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

void registerUserRoutes(
  Router router,
  LocalApiContext context,
  SafeHandler safe,
) {
  router.get(
    '/api/users/bootstrap-status',
    safe((request) => _bootstrapStatus(request, context)),
  );
  router.post(
    '/api/users/bootstrap-admin',
    safe((request) => _bootstrapAdmin(request, context)),
  );
  router.post('/api/users/login', safe((request) => _login(request, context)));
  router.get(
    '/api/users/profile',
    safe((request) => _profile(request, context)),
  );
  router.get('/api/users', safe((request) => _users(request, context)));
  router.post('/api/users', safe((request) => _createUser(request, context)));
  router.put(
    '/api/users/<id>',
    safe((request) => _updateUser(request, context)),
  );
  router.delete(
    '/api/users/<id>',
    safe((request) => _deleteUser(request, context)),
  );
}

Future<Response> _bootstrapStatus(
  Request request,
  LocalApiContext context,
) async {
  final hasUsers = context.database.read(
    (db) =>
        intValue(db.select('SELECT count(*) AS c FROM users').first['c']) > 0,
  );
  return jsonResponse({'hasUsers': hasUsers});
}

Future<Response> _bootstrapAdmin(
  Request request,
  LocalApiContext context,
) async {
  final body = await jsonBody(request);
  final username = (body['username'] as String?)?.trim();
  final password = body['password'] as String?;
  if (username == null ||
      username.isEmpty ||
      password == null ||
      password.length < 8) {
    throw const HttpError(400, 'Validation error');
  }
  final user = await context.database.transaction((db) {
    if (_userCount(db) > 0) {
      throw const HttpError(409, 'Bootstrap admin already exists');
    }
    _ensureUniqueUsername(db, username: username);
    final email = _generateCompatibilityEmail(db);
    db.execute(
      '''
INSERT INTO users (username, email, password_hash, role)
VALUES (?, ?, ?, ?)
''',
      [username, email, context.auth.hashPassword(password), 'administrador'],
    );
    return db.select('SELECT * FROM users WHERE id = ?', [
      db.lastInsertRowId,
    ]).first;
  });
  final token = context.auth.signToken(
    userId: intValue(user['id']),
    email: user['email'] as String,
    role: user['role'] as String? ?? 'administrador',
  );
  return jsonResponse({
    'message': 'Admin bootstrap successful',
    'user': userJson(user),
    'token': token,
  }, status: 201);
}

Future<Response> _login(Request request, LocalApiContext context) async {
  final body = await jsonBody(request);
  final username = (body['username'] as String?)?.trim();
  final password = body['password'] as String?;
  if (username == null || username.isEmpty || password == null) {
    throw const HttpError(400, 'Validation error');
  }
  final rows = context.database.read(
    (db) => db.select('SELECT * FROM users WHERE lower(username) = lower(?)', [
      username,
    ]),
  );
  if (rows.isEmpty ||
      !context.auth.verifyPassword(
        password,
        rows.first['password_hash'] as String,
      )) {
    throw const HttpError(401, 'Invalid credentials');
  }
  final user = rows.first;
  final token = context.auth.signToken(
    userId: intValue(user['id']),
    email: user['email'] as String,
    role: user['role'] as String? ?? 'user',
  );
  return jsonResponse({
    'message': 'Login successful',
    'user': userJson(user),
    'token': token,
  });
}

Future<Response> _profile(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  final user = context.userById(claims.userId);
  return jsonResponse(userJson(user));
}

Future<Response> _users(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'user', 'read');
  final rows = context.database.read(
    (db) => db.select('SELECT * FROM users ORDER BY username ASC'),
  );
  return jsonResponse({'users': rows.map(userJson).toList()});
}

Future<Response> _createUser(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'user', 'create');
  final body = await jsonBody(request);
  final username = (body['username'] as String?)?.trim();
  final password = body['password'] as String?;
  final role = (body['role'] as String?)?.trim() ?? 'user';
  if (username == null ||
      username.isEmpty ||
      password == null ||
      password.length < 8 ||
      !_isSupportedRole(role)) {
    throw const HttpError(400, 'Validation error');
  }

  final user = await context.database.transaction((db) {
    _ensureUniqueUsername(db, username: username);
    final email = _generateCompatibilityEmail(db);
    db.execute(
      '''
INSERT INTO users (username, email, password_hash, role)
VALUES (?, ?, ?, ?)
''',
      [username, email, context.auth.hashPassword(password), role],
    );
    final userId = db.lastInsertRowId;
    _syncRolePrivileges(
      db,
      userId: userId,
      role: role,
      grantedBy: claims.userId,
    );
    return db.select('SELECT * FROM users WHERE id = ?', [userId]).first;
  });
  return jsonResponse(userJson(user), status: 201);
}

Future<Response> _updateUser(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'user', 'update');
  final id = int.tryParse(request.params['id'] ?? '');
  if (id == null) throw const HttpError(400, 'Invalid user id');
  final body = await jsonBody(request);
  final user = await context.database.transaction((db) {
    final existingRows = db.select('SELECT * FROM users WHERE id = ?', [id]);
    if (existingRows.isEmpty) throw const HttpError(404, 'User not found');
    final existing = existingRows.first;
    final nextUsername = body.containsKey('username')
        ? (body['username'] as String).trim()
        : existing['username'] as String;
    final nextRole = body.containsKey('role')
        ? (body['role'] as String).trim()
        : (existing['role'] as String? ?? 'user');
    if (nextUsername.isEmpty || !_isSupportedRole(nextRole)) {
      throw const HttpError(400, 'Validation error');
    }
    if ((existing['role'] as String? ?? 'user').toLowerCase() ==
            'administrador' &&
        nextRole.toLowerCase() != 'administrador' &&
        _adminCount(db) <= 1) {
      throw const HttpError(400, 'At least one admin is required');
    }
    _ensureUniqueUsername(db, username: nextUsername, excludeUserId: id);

    final fields = <String>['username = ?', 'role = ?'];
    final args = <Object?>[nextUsername, nextRole];
    if (body.containsKey('password')) {
      final password = body['password'] as String?;
      if (password == null || password.isEmpty || password.length < 8) {
        throw const HttpError(400, 'Validation error');
      }
      fields.add('password_hash = ?');
      args.add(context.auth.hashPassword(password));
    }
    args.add(id);
    db.execute('UPDATE users SET ${fields.join(', ')} WHERE id = ?', args);
    _syncRolePrivileges(
      db,
      userId: id,
      role: nextRole,
      grantedBy: claims.userId,
    );
    return db.select('SELECT * FROM users WHERE id = ?', [id]).first;
  });
  return jsonResponse(userJson(user));
}

Future<Response> _deleteUser(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'user', 'delete');
  final id = int.tryParse(request.params['id'] ?? '');
  if (id == null) throw const HttpError(400, 'Invalid user id');
  await context.database.transaction((db) {
    final rows = db.select('SELECT * FROM users WHERE id = ?', [id]);
    if (rows.isEmpty) throw const HttpError(404, 'User not found');
    if (id == claims.userId) {
      throw const HttpError(400, 'Cannot delete the current user');
    }
    final role = rows.first['role'] as String? ?? 'user';
    if (role.toLowerCase() == 'administrador' && _adminCount(db) <= 1) {
      throw const HttpError(400, 'At least one admin is required');
    }
    db.execute('DELETE FROM users WHERE id = ?', [id]);
  });
  return jsonResponse({'message': 'User deleted'});
}

void _ensureUniqueUsername(
  Database db, {
  required String username,
  int? excludeUserId,
}) {
  final usernameRows = excludeUserId == null
      ? db.select('SELECT id FROM users WHERE lower(username) = lower(?)', [
          username,
        ])
      : db.select(
          'SELECT id FROM users WHERE lower(username) = lower(?) AND id != ?',
          [username, excludeUserId],
        );
  if (usernameRows.isNotEmpty) {
    throw const HttpError(400, 'Username already exists');
  }
}

String _generateCompatibilityEmail(Database db) {
  while (true) {
    final email = 'local-user-${uuidValue()}@local.internal';
    final rows = db.select('SELECT id FROM users WHERE email = ?', [email]);
    if (rows.isEmpty) return email;
  }
}

void _syncRolePrivileges(
  Database db, {
  required int userId,
  required String role,
  required int grantedBy,
}) {
  db.execute('DELETE FROM user_privileges WHERE user_id = ?', [userId]);
  final privilegeNames =
      _rolePrivilegeNames[role.toLowerCase()] ?? const <String>[];
  for (final name in privilegeNames) {
    final rows = db.select('SELECT id FROM privileges WHERE name = ?', [name]);
    if (rows.isEmpty) continue;
    db.execute(
      '''
INSERT OR IGNORE INTO user_privileges (user_id, privilege_id, granted_by, is_active)
VALUES (?, ?, ?, 1)
''',
      [userId, rows.first['id'], grantedBy],
    );
  }
}

int _userCount(Database db) =>
    intValue(db.select('SELECT count(*) AS c FROM users').first['c']);

int _adminCount(Database db) => intValue(
  db
      .select(
        "SELECT count(*) AS c FROM users WHERE lower(role) = 'administrador'",
      )
      .first['c'],
);

bool _isSupportedRole(String role) =>
    _supportedRoles.contains(role.toLowerCase());

const _supportedRoles = {'administrador', 'cajero', 'user'};

const Map<String, List<String>> _rolePrivilegeNames = {
  'cajero': ['bill.create', 'bill.read', 'item.read', 'client.read'],
  'user': ['bill.read', 'item.read'],
  'administrador': [],
};
