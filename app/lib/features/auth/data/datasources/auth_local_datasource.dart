import 'package:app/features/auth/domain/entities/session.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession(Session session);
  Future<Session?> getSession();
  Future<void> clearSession();
}
