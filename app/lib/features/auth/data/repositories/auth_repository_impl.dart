import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dio/dio.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<Session, Failure>> login(String email, String password) async {
    try {
      final response = await _remote.login(email, password);
      final session = Session(
        token: response.token,
        user: response.user.toEntity(),
      );
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
  Future<void> logout() async {
    await _local.clearSession();
  }

  @override
  Future<Session?> getSession() async {
    return _local.getSession();
  }

  String _messageFromDioException(DioException e) {
    final msg = e.message;
    if (msg != null && msg.isNotEmpty) return msg;
    final statusCode = e.response?.statusCode;
    if (statusCode != null) return 'Error del servidor: $statusCode';
    return 'Error de conexión';
  }
}
