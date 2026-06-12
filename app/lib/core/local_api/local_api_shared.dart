import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app/core/local_api/local_auth.dart';
import 'package:app/core/local_api/local_database.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

typedef SafeHandler =
    Handler Function(Future<Response> Function(Request request) handler);

class HttpError implements Exception {
  const HttpError(this.status, this.message);

  final int status;
  final String message;
}

class LocalApiContext {
  const LocalApiContext({required this.database, required this.auth});

  final LocalDatabase database;
  final LocalAuth auth;

  LocalTokenClaims requireAuth(Request request) {
    final header = request.headers[HttpHeaders.authorizationHeader];
    final token = header != null && header.startsWith('Bearer ')
        ? header.substring(7)
        : null;
    if (token == null) throw const HttpError(401, 'No token provided');
    final claims = auth.verifyToken(token);
    if (claims == null) throw const HttpError(401, 'Invalid token');
    final user = userById(claims.userId);
    return LocalTokenClaims(
      userId: claims.userId,
      email: user['email'] as String,
      role: user['role'] as String? ?? claims.role,
    );
  }

  void requirePrivilege(
    int userId,
    String role,
    String resource,
    String action,
  ) {
    if (!hasPrivilege(userId, role, resource, action)) {
      throw HttpError(
        403,
        'Insufficient privileges. Required: $resource.$action',
      );
    }
  }

  bool hasPrivilege(int userId, String role, String resource, String action) {
    if (role.toLowerCase() == 'administrador') return true;
    return database.read((db) {
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

  Row userById(int userId) {
    final rows = database.read(
      (db) => db.select('SELECT * FROM users WHERE id = ?', [userId]),
    );
    if (rows.isEmpty) throw const HttpError(401, 'User not found');
    return rows.first;
  }
}

Future<Map<String, dynamic>> jsonBody(Request request) async {
  final raw = await request.readAsString();
  if (raw.isEmpty) return <String, dynamic>{};
  return jsonDecode(raw) as Map<String, dynamic>;
}

Response jsonResponse(Object value, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(value),
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  );
}

Map<String, dynamic> userJson(Row row) => {
  'id': intValue(row['id']),
  'username': row['username'],
  'email': row['email'],
  'role': row['role'],
};

int limitValue(String? raw) => min(100, max(1, int.tryParse(raw ?? '') ?? 50));

int offsetValue(String? raw) => max(0, int.tryParse(raw ?? '') ?? 0);

int? intFromBody(Object? value) {
  if (value == null || value == '') return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? numFromBody(Object? value) {
  if (value == null || value == '') return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? nullableTrim(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int intValue(Object? value) =>
    value is int ? value : int.parse(value.toString());

double doubleValue(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

double round2(double value) => (value * 100).roundToDouble() / 100;

String isoDate(Object? value) {
  final text = value?.toString() ?? DateTime.now().toIso8601String();
  if (text.contains('T')) return text;
  return DateTime.tryParse(text)?.toIso8601String() ??
      DateTime.now().toIso8601String();
}

String uuidValue() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
