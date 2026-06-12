import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/users/domain/entities/local_user_entity.dart';

abstract class LocalUsersRepository {
  Future<Result<List<LocalUserEntity>, Failure>> getUsers();
  Future<Result<LocalUserEntity, Failure>> createUser({
    required String username,
    required String email,
    required String password,
    required String role,
  });
  Future<Result<LocalUserEntity, Failure>> updateUser({
    required int id,
    required String username,
    required String email,
    String? password,
    required String role,
  });
  Future<Result<void, Failure>> deleteUser(int id);
}
