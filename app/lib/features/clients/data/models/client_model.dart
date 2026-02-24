import 'package:app/features/clients/domain/entities/client_entity.dart';

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.name,
    super.identifier,
    super.taxId,
    super.email,
    super.phone,
    super.address,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as int,
      name: json['name'] as String,
      identifier: json['identifier'] as String?,
      taxId: json['taxId'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }

  ClientEntity toEntity() => ClientEntity(
        id: id,
        name: name,
        identifier: identifier,
        taxId: taxId,
        email: email,
        phone: phone,
        address: address,
      );
}
