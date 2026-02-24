import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/clients/domain/repositories/clients_repository.dart';

class GetClientsUseCase {
  GetClientsUseCase(this._repository);

  final ClientsRepository _repository;

  Future<Result<ClientsListResult, Failure>> call({
    String? search,
    int limit = 50,
    int offset = 0,
  }) =>
      _repository.getClients(
        search: search,
        limit: limit,
        offset: offset,
      );
}
