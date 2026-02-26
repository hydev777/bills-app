import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/clients/domain/entities/client_entity.dart';
import 'package:app/features/clients/domain/repositories/clients_repository.dart';

class UpdateClientUseCase {
  UpdateClientUseCase(this._repository);

  final ClientsRepository _repository;

  Future<Result<ClientEntity, Failure>> call({
    required int id,
    required String name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  }) {
    return _repository.updateClient(
      id,
      name: name,
      identifier: identifier,
      taxId: taxId,
      email: email,
      phone: phone,
      address: address,
    );
  }
}
