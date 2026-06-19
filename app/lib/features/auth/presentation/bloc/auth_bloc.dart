import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/auth/domain/usecases/create_initial_admin_usecase.dart';
import 'package:app/features/auth/domain/usecases/get_session_usecase.dart';
import 'package:app/features/auth/domain/usecases/has_local_users_usecase.dart';
import 'package:app/features/auth/domain/usecases/login_usecase.dart';
import 'package:app/features/auth/domain/usecases/logout_usecase.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetSessionUseCase getSessionUseCase,
    required HasLocalUsersUseCase hasLocalUsersUseCase,
    required CreateInitialAdminUseCase createInitialAdminUseCase,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _getSessionUseCase = getSessionUseCase,
       _hasLocalUsersUseCase = hasLocalUsersUseCase,
       _createInitialAdminUseCase = createInitialAdminUseCase,
       super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthInitialAdminCreateRequested>(_onInitialAdminCreateRequested);
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetSessionUseCase _getSessionUseCase;
  final HasLocalUsersUseCase _hasLocalUsersUseCase;
  final CreateInitialAdminUseCase _createInitialAdminUseCase;

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUseCase.call(event.identifier, event.password);
    result.fold(
      onSuccess: (session) => emit(AuthAuthenticated(session)),
      onFailure: (f) => emit(AuthError(f.displayMessage)),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase.call();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    final session = await _getSessionUseCase.call();
    if (session != null) {
      emit(AuthAuthenticated(session));
      return;
    }
    final result = await _hasLocalUsersUseCase.call();
    result.fold(
      onSuccess: (hasUsers) {
        if (hasUsers) {
          emit(const AuthUnauthenticated());
        } else {
          emit(const AuthBootstrapRequired());
        }
      },
      onFailure: (f) => emit(AuthError(f.displayMessage)),
    );
  }

  Future<void> _onInitialAdminCreateRequested(
    AuthInitialAdminCreateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _createInitialAdminUseCase.call(
      username: event.username,
      password: event.password,
    );
    result.fold(
      onSuccess: (session) => emit(AuthAuthenticated(session)),
      onFailure: (f) => emit(AuthBootstrapRequired(message: f.displayMessage)),
    );
  }
}
