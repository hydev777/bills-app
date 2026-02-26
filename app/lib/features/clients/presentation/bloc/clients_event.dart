import 'package:equatable/equatable.dart';

sealed class ClientsEvent extends Equatable {
  const ClientsEvent();

  @override
  List<Object?> get props => [];
}

/// Load clients list (on open / refresh).
final class ClientsLoaded extends ClientsEvent {
  const ClientsLoaded();
}

/// Create a new client.
final class ClientCreated extends ClientsEvent {
  const ClientCreated({
    required this.name,
    this.identifier,
    this.taxId,
    this.email,
    this.phone,
    this.address,
  });

  final String name;
  final String? identifier;
  final String? taxId;
  final String? email;
  final String? phone;
  final String? address;

  @override
  List<Object?> get props => [name, identifier, taxId, email, phone, address];
}

/// Update an existing client.
final class ClientUpdated extends ClientsEvent {
  const ClientUpdated({
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
  List<Object?> get props => [id, name, identifier, taxId, email, phone, address];
}
