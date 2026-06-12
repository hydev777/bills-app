import 'package:equatable/equatable.dart';

import 'package:app/features/users/domain/entities/local_user_entity.dart';

sealed class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

final class UsersInitial extends UsersState {
  const UsersInitial();
}

final class UsersLoading extends UsersState {
  const UsersLoading();
}

final class UsersLoadedState extends UsersState {
  const UsersLoadedState(this.users);

  final List<LocalUserEntity> users;

  @override
  List<Object?> get props => [users];
}

final class UsersError extends UsersState {
  const UsersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
