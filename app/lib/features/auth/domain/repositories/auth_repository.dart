import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/domain/entities/session.dart';

abstract class AuthRepository {
  Future<Result<Session, Failure>> login(String identifier, String password);
  Future<Result<bool, Failure>> hasLocalUsers();
  Future<Result<Session, Failure>> createInitialAdmin({
    required String username,
    required String password,
  });
  Future<void> logout();
  Future<Session?> getSession();
}
