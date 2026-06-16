import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/core/constants/api_constants.dart';
import 'package:app/features/auth/data/models/branch_model.dart';
import 'package:app/features/auth/data/models/login_response.dart';
import 'package:app/features/auth/domain/entities/branch_entity.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dio/dio.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<Session, Failure>> login(
    String identifier,
    String password,
  ) async {
    try {
      final response = ApiConstants.isLocal
          ? await _remote.loginLocal(identifier, password)
          : await _remote.login(identifier, password);
      final session = _sessionFromLoginResponse(response);
      await _local.saveSession(session);
      return success(session);
    } on DioException catch (e) {
      final message = _messageFromDioException(e);
      if (e.response?.statusCode == 401) {
        return failure(const AuthFailure(message: 'Credenciales incorrectas'));
      }
      return failure(ServerFailure(message: message));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<bool, Failure>> hasLocalUsers() async {
    try {
      final hasUsers = await _remote.hasLocalUsers();
      return success(hasUsers);
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDioException(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Session, Failure>> createInitialAdmin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _remote.createInitialAdmin(
        username: username,
        password: password,
      );
      final session = _sessionFromLoginResponse(response);
      await _local.saveSession(session);
      return success(session);
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDioException(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await _local.clearSession();
  }

  @override
  Future<Session?> getSession() async {
    return _local.getSession();
  }

  Session _sessionFromLoginResponse(LoginResponse response) {
    final branches = response.accessibleBranches
        .map<BranchEntity>((b) => b.toEntity())
        .toList(growable: false);
    final selectedBranchId = _selectDefaultBranch(response.accessibleBranches);
    return Session(
      token: response.token,
      user: response.user.toEntity(),
      accessibleBranches: branches,
      selectedBranchId: selectedBranchId,
    );
  }

  int? _selectDefaultBranch(List<BranchModel> branches) {
    if (branches.isEmpty) return null;
    for (final b in branches) {
      if (b.isPrimary && b.canLogin) return b.id;
    }
    for (final b in branches) {
      if (b.canLogin) return b.id;
    }
    return branches.first.id;
  }

  String _messageFromDioException(DioException e) {
    final msg = e.message;
    if (msg != null && msg.isNotEmpty) return msg;
    final statusCode = e.response?.statusCode;
    if (statusCode != null) return 'Error del servidor: $statusCode';
    return 'Error de conexión';
  }
}
