import 'package:app/features/users/data/models/local_user_model.dart';

abstract class LocalUsersRemoteDataSource {
  Future<List<LocalUserModel>> getUsers();
  Future<LocalUserModel> createUser({
    required String username,
    required String password,
    required String role,
  });
  Future<LocalUserModel> updateUser({
    required int id,
    required String username,
    String? password,
    required String role,
  });
  Future<void> deleteUser(int id);
}
