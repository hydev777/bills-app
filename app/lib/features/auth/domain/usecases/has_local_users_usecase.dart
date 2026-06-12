import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

class HasLocalUsersUseCase {
  HasLocalUsersUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<bool, Failure>> call() => _repository.hasLocalUsers();
}
