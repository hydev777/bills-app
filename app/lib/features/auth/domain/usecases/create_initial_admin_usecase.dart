import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

class CreateInitialAdminUseCase {
  CreateInitialAdminUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Session, Failure>> call({
    required String username,
    required String password,
  }) {
    return _repository.createInitialAdmin(
      username: username,
      password: password,
    );
  }
}
