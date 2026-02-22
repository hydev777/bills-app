import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/domain/entities/session.dart';

abstract class AuthRepository {
  Future<Result<Session, Failure>> login(String email, String password);
  Future<void> logout();
  Future<Session?> getSession();
}
