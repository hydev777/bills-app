import 'package:app/features/auth/data/models/user_model.dart';

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.user,
  });

  final String token;
  final UserModel user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
