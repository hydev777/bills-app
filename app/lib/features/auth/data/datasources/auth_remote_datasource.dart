import 'package:app/features/auth/data/models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(String email, String password);
  Future<LoginResponse> loginLocal(String username, String password);
  Future<bool> hasLocalUsers();
  Future<LoginResponse> createInitialAdmin({
    required String username,
    required String password,
  });
}
