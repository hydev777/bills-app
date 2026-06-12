import 'package:app/features/users/domain/entities/local_user_entity.dart';

class LocalUserModel extends LocalUserEntity {
  const LocalUserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.role,
  });

  factory LocalUserModel.fromJson(Map<String, dynamic> json) {
    return LocalUserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
    );
  }
}
