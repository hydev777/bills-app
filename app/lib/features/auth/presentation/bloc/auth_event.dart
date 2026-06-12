import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthSessionRequested extends AuthEvent {
  const AuthSessionRequested();
}

final class AuthInitialAdminCreateRequested extends AuthEvent {
  const AuthInitialAdminCreateRequested({
    required this.username,
    required this.email,
    required this.password,
  });

  final String username;
  final String email;
  final String password;

  @override
  List<Object?> get props => [username, email, password];
}
