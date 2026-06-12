import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/users/domain/entities/local_user_entity.dart';
import 'package:app/features/users/domain/repositories/local_users_repository.dart';

class UpdateLocalUserUseCase {
  UpdateLocalUserUseCase(this._repository);

  final LocalUsersRepository _repository;

  Future<Result<LocalUserEntity, Failure>> call({
    required int id,
    required String username,
    required String email,
    String? password,
    required String role,
  }) {
    return _repository.updateUser(
      id: id,
      username: username,
      email: email,
      password: password,
      role: role,
    );
  }
}
