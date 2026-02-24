import 'package:equatable/equatable.dart';

import 'package:app/features/clients/domain/entities/client_entity.dart';

sealed class ClientsState extends Equatable {
  const ClientsState();

  @override
  List<Object?> get props => [];
}

final class ClientsInitial extends ClientsState {
  const ClientsInitial();
}

final class ClientsLoading extends ClientsState {
  const ClientsLoading();
}

final class ClientsLoadedState extends ClientsState {
  const ClientsLoadedState({
    required this.clients,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<ClientEntity> clients;
  final int total;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [clients, total, limit, offset];
}

final class ClientsError extends ClientsState {
  const ClientsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
