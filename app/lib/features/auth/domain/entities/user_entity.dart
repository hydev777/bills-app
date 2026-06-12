import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  final int id;
  final String username;
  final String email;
  final String role;

  @override
  List<Object?> get props => [id, username, email, role];
}
