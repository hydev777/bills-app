import 'package:equatable/equatable.dart';

class ClientEntity extends Equatable {
  const ClientEntity({
    required this.id,
    required this.name,
    this.identifier,
    this.taxId,
    this.email,
    this.phone,
    this.address,
  });

  final int id;
  final String name;
  final String? identifier;
  final String? taxId;
  final String? email;
  final String? phone;
  final String? address;

  @override
  List<Object?> get props =>
      [id, name, identifier, taxId, email, phone, address];
}
