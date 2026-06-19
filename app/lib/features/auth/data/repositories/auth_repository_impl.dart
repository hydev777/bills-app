import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/data/datasources/auth_local_api_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/data/models/login_response.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalApiDataSource localApi,
    required AuthLocalDataSource local,
  }) : _localApi = localApi,
       _local = local;

  final AuthLocalApiDataSource _localApi;
  final AuthLocalDataSource _local;

  @override
  Future<Result<Session, Failure>> login(
    String identifier,
    String password,
  ) async {
    try {
      final response = await _localApi.login(identifier, password);
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
      final hasUsers = await _localApi.hasLocalUsers();
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
      final response = await _localApi.createInitialAdmin(
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
    return Session(token: response.token, user: response.user.toEntity());
  }

  String _messageFromDioException(DioException e) {
    final msg = e.message;
    if (msg != null && msg.isNotEmpty) return msg;
    final statusCode = e.response?.statusCode;
    if (statusCode != null) return 'Error del servidor: $statusCode';
    return 'Error de conexion';
  }
}
