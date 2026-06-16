import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/features/users/domain/usecases/create_local_user_usecase.dart';
import 'package:app/features/users/domain/usecases/delete_local_user_usecase.dart';
import 'package:app/features/users/domain/usecases/get_local_users_usecase.dart';
import 'package:app/features/users/domain/usecases/update_local_user_usecase.dart';
import 'package:app/injection.dart';

import 'users_event.dart';
import 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({
    required GetLocalUsersUseCase getLocalUsersUseCase,
    required CreateLocalUserUseCase createLocalUserUseCase,
    required UpdateLocalUserUseCase updateLocalUserUseCase,
    required DeleteLocalUserUseCase deleteLocalUserUseCase,
  }) : _getLocalUsersUseCase = getLocalUsersUseCase,
       _createLocalUserUseCase = createLocalUserUseCase,
       _updateLocalUserUseCase = updateLocalUserUseCase,
       _deleteLocalUserUseCase = deleteLocalUserUseCase,
       super(const UsersInitial()) {
    on<UsersLoaded>(_onUsersLoaded);
    on<UserCreated>(_onUserCreated);
    on<UserUpdated>(_onUserUpdated);
    on<UserDeleted>(_onUserDeleted);
  }

  final GetLocalUsersUseCase _getLocalUsersUseCase;
  final CreateLocalUserUseCase _createLocalUserUseCase;
  final UpdateLocalUserUseCase _updateLocalUserUseCase;
  final DeleteLocalUserUseCase _deleteLocalUserUseCase;

  Future<void> _onUsersLoaded(
    UsersLoaded event,
    Emitter<UsersState> emit,
  ) async {
    emit(const UsersLoading());
    final result = await _getLocalUsersUseCase.call();
    result.fold(
      onSuccess: (users) => emit(UsersLoadedState(users)),
      onFailure: (f) => emit(UsersError(f.displayMessage)),
    );
  }

  Future<void> _reload(Emitter<UsersState> emit) async {
    final result = await _getLocalUsersUseCase.call();
    result.fold(
      onSuccess: (users) => emit(UsersLoadedState(users)),
      onFailure: (f) => emit(UsersError(f.displayMessage)),
    );
    sl<AuthBloc>().add(const AuthSessionRequested());
  }

  Future<void> _onUserCreated(
    UserCreated event,
    Emitter<UsersState> emit,
  ) async {
    final result = await _createLocalUserUseCase.call(
      username: event.username,
      password: event.password,
      role: event.role,
    );
    await result.when<Future<void>>(
      success: (_) async => _reload(emit),
      failure: (f) async => emit(UsersError(f.displayMessage)),
    );
  }

  Future<void> _onUserUpdated(
    UserUpdated event,
    Emitter<UsersState> emit,
  ) async {
    final result = await _updateLocalUserUseCase.call(
      id: event.id,
      username: event.username,
      password: event.password,
      role: event.role,
    );
    await result.when<Future<void>>(
      success: (_) async => _reload(emit),
      failure: (f) async => emit(UsersError(f.displayMessage)),
    );
  }

  Future<void> _onUserDeleted(
    UserDeleted event,
    Emitter<UsersState> emit,
  ) async {
    final result = await _deleteLocalUserUseCase.call(event.id);
    await result.when<Future<void>>(
      success: (_) async => _reload(emit),
      failure: (f) async => emit(UsersError(f.displayMessage)),
    );
  }
}
