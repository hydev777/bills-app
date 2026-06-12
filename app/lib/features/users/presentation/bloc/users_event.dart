import 'package:equatable/equatable.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

final class UsersLoaded extends UsersEvent {
  const UsersLoaded();
}

final class UserCreated extends UsersEvent {
  const UserCreated({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
  });

  final String username;
  final String email;
  final String password;
  final String role;

  @override
  List<Object?> get props => [username, email, password, role];
}

final class UserUpdated extends UsersEvent {
  const UserUpdated({
    required this.id,
    required this.username,
    required this.email,
    this.password,
    required this.role,
  });

  final int id;
  final String username;
  final String email;
  final String? password;
  final String role;

  @override
  List<Object?> get props => [id, username, email, password, role];
}

final class UserDeleted extends UsersEvent {
  const UserDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
