import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/clients/domain/entities/client_entity.dart';
import 'package:app/features/clients/domain/repositories/clients_repository.dart';

class CreateClientUseCase {
  CreateClientUseCase(this._repository);

  final ClientsRepository _repository;

  Future<Result<ClientEntity, Failure>> call({
    required String name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  }) {
    return _repository.createClient(
      name: name,
      identifier: identifier,
      taxId: taxId,
      email: email,
      phone: phone,
      address: address,
    );
  }
}

