import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/users/domain/repositories/local_users_repository.dart';

class DeleteLocalUserUseCase {
  DeleteLocalUserUseCase(this._repository);

  final LocalUsersRepository _repository;

  Future<Result<void, Failure>> call(int id) => _repository.deleteUser(id);
}
