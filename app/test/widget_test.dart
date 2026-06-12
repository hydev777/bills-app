import 'package:app/app.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/usecases/get_session_usecase.dart';
import 'package:app/features/auth/domain/usecases/has_local_users_usecase.dart';
import 'package:app/features/auth/domain/usecases/login_usecase.dart';
import 'package:app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app/features/auth/domain/usecases/create_initial_admin_usecase.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/injection.dart';
import 'package:app/router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Session?> getSession() async => null;

  @override
  Future<Result<bool, Failure>> hasLocalUsers() async => success(true);

  @override
  Future<Result<Session, Failure>> login(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Session, Failure>> createInitialAdmin({
    required String username,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

void main() {
  setUp(() async {
    await sl.reset();
    dotenv.loadFromString(
      envString: '''
ENV=dev
BASE_URL_DEV=http://localhost:3000
BASE_URL_PROD=https://api.example.com
''',
    );
    final repository = _FakeAuthRepository();
    sl.registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        loginUseCase: LoginUseCase(repository),
        logoutUseCase: LogoutUseCase(repository),
        getSessionUseCase: GetSessionUseCase(repository),
        hasLocalUsersUseCase: HasLocalUsersUseCase(repository),
        createInitialAdminUseCase: CreateInitialAdminUseCase(repository),
      ),
    );
    initRouter();
  });

  testWidgets('shows login screen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Facturacion'), findsOneWidget);
    expect(find.text('Inicie sesion para continuar'), findsOneWidget);
  });
}
