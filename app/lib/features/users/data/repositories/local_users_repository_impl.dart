import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/entities/user_entity.dart';
import 'package:app/features/users/data/datasources/local_users_remote_datasource.dart';
import 'package:app/features/users/domain/entities/local_user_entity.dart';
import 'package:app/features/users/domain/repositories/local_users_repository.dart';
import 'package:dio/dio.dart';

class LocalUsersRepositoryImpl implements LocalUsersRepository {
  LocalUsersRepositoryImpl({
    required LocalUsersRemoteDataSource remote,
    required AuthLocalDataSource authLocalDataSource,
  }) : _remote = remote,
       _authLocalDataSource = authLocalDataSource;

  final LocalUsersRemoteDataSource _remote;
  final AuthLocalDataSource _authLocalDataSource;

  @override
  Future<Result<List<LocalUserEntity>, Failure>> getUsers() async {
    try {
      final users = await _remote.getUsers();
      return success(users);
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDioException(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<LocalUserEntity, Failure>> createUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final user = await _remote.createUser(
        username: username,
        email: email,
        password: password,
        role: role,
      );
      return success(user);
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDioException(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<LocalUserEntity, Failure>> updateUser({
    required int id,
    required String username,
    required String email,
    String? password,
    required String role,
  }) async {
    try {
      final user = await _remote.updateUser(
        id: id,
        username: username,
        email: email,
        password: password,
        role: role,
      );
      await _refreshCurrentSessionIfNeeded(user);
      return success(user);
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDioException(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteUser(int id) async {
    try {
      await _remote.deleteUser(id);
      return success(null);
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDioException(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  Future<void> _refreshCurrentSessionIfNeeded(
    LocalUserEntity updatedUser,
  ) async {
    final session = await _authLocalDataSource.getSession();
    if (session == null || session.user.id != updatedUser.id) return;
    await _authLocalDataSource.saveSession(
      Session(
        token: session.token,
        user: UserEntity(
          id: updatedUser.id,
          username: updatedUser.username,
          email: updatedUser.email,
          role: updatedUser.role,
        ),
        accessibleBranches: session.accessibleBranches,
        selectedBranchId: session.selectedBranchId,
      ),
    );
  }

  String _messageFromDioException(DioException e) {
    final responseMessage = e.response?.data is Map<String, dynamic>
        ? (e.response?.data as Map<String, dynamic>)['error'] as String?
        : null;
    if (responseMessage != null && responseMessage.isNotEmpty) {
      return responseMessage;
    }
    final message = e.message;
    if (message != null && message.isNotEmpty) return message;
    return 'Error de conexion';
  }
}
