import 'package:app/features/auth/domain/entities/session.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

class GetSessionUseCase {
  GetSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Session?> call() => _repository.getSession();
}
