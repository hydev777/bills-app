import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/users/domain/entities/local_user_entity.dart';
import 'package:app/features/users/domain/repositories/local_users_repository.dart';

class GetLocalUsersUseCase {
  GetLocalUsersUseCase(this._repository);

  final LocalUsersRepository _repository;

  Future<Result<List<LocalUserEntity>, Failure>> call() =>
      _repository.getUsers();
}
