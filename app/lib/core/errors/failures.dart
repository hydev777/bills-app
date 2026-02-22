import 'package:equatable/equatable.dart';

/// Base type for domain/API failures.
abstract base class Failure extends Equatable {
  const Failure({this.message});

  final String? message;

  String get displayMessage => message ?? 'Ha ocurrido un error';

  @override
  List<Object?> get props => [message];
}

/// Authentication failures (invalid credentials, token expired, etc.).
final class AuthFailure extends Failure {
  const AuthFailure({super.message});
}

/// Server/network failures (timeout, 5xx, connection error).
final class ServerFailure extends Failure {
  const ServerFailure({super.message});
}
