import 'package:equatable/equatable.dart';

class LocalUserEntity extends Equatable {
  const LocalUserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  final int id;
  final String username;
  final String email;
  final String role;

  bool get isAdmin => role.toLowerCase() == 'administrador';

  @override
  List<Object?> get props => [id, username, email, role];
}
