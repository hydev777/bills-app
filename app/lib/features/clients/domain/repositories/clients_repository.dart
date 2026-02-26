import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/clients/domain/entities/client_entity.dart';

abstract class ClientsRepository {
  /// Returns clients list with pagination. GET /api/clients.
  Future<Result<ClientsListResult, Failure>> getClients({
    String? search,
    int limit = 50,
    int offset = 0,
  });

  /// Create a new client. POST /api/clients.
  Future<Result<ClientEntity, Failure>> createClient({
    required String name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  });

  /// Update a client. PUT /api/clients/:id.
  Future<Result<ClientEntity, Failure>> updateClient(
    int id, {
    required String name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  });
}

class ClientsListResult {
  const ClientsListResult({
    required this.clients,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<ClientEntity> clients;
  final int total;
  final int limit;
  final int offset;
}
