import 'dart:convert';

import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/data/models/branch_model.dart';
import 'package:app/features/auth/domain/entities/branch_entity.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyToken = 'auth_token';
const _keyUser = 'auth_user';
const _keyBranches = 'auth_branches';
const _keySelectedBranchId = 'auth_selected_branch_id';

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
    final branchesJson = jsonEncode(
      session.accessibleBranches
          .map((b) => {
                'id': b.id,
                'name': b.name,
                'code': b.code,
                'isPrimary': b.isPrimary,
                'canLogin': b.canLogin,
              })
          .toList(),
    );
    await _storage.write(key: _keyBranches, value: branchesJson);
    await _storage.write(
      key: _keySelectedBranchId,
      value: session.selectedBranchId?.toString(),
    );
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

    List<BranchEntity> branches = [];
    final branchesStr = await _storage.read(key: _keyBranches);
    if (branchesStr != null && branchesStr.isNotEmpty) {
      final list = jsonDecode(branchesStr) as List<dynamic>;
      branches = list
          .map((e) => BranchModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
    }

    int? selectedBranchId;
    final branchIdStr = await _storage.read(key: _keySelectedBranchId);
    if (branchIdStr != null && branchIdStr.isNotEmpty) {
      selectedBranchId = int.tryParse(branchIdStr);
    }

    return Session(
      token: token,
      user: user,
      accessibleBranches: branches,
      selectedBranchId: selectedBranchId,
    );
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keyBranches);
    await _storage.delete(key: _keySelectedBranchId);
  }
}
