import 'package:app/features/auth/data/models/login_response.dart';

abstract class AuthLocalApiDataSource {
  Future<LoginResponse> login(String username, String password);
  Future<bool> hasLocalUsers();
  Future<LoginResponse> createInitialAdmin({
    required String username,
    required String password,
  });
}
