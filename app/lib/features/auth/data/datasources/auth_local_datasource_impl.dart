import 'dart:convert';

import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyToken = 'auth_token';
const _keyUser = 'auth_user';

class AuthLocalDataSourceImpl extends AuthLocalDataSource {
  AuthLocalDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveSession(Session session) async {
    await _storage.write(key: _keyToken, value: session.token);
    final userJson = jsonEncode({
      'id': session.user.id,
      'username': session.user.username,
      'email': session.user.email,
    });
    await _storage.write(key: _keyUser, value: userJson);
  }

  @override
  Future<Session?> getSession() async {
    final token = await _storage.read(key: _keyToken);
    final userJson = await _storage.read(key: _keyUser);
    if (token == null || token.isEmpty || userJson == null) return null;

    final map = jsonDecode(userJson) as Map<String, dynamic>;
    final user = UserEntity(
      id: map['id'] as int,
      username: map['username'] as String,
      email: map['email'] as String,
    );
    return Session(token: token, user: user);
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }
}
