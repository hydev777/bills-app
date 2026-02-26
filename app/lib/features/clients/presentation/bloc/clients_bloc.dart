import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/clients/domain/usecases/get_clients_usecase.dart';
import 'package:app/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:app/features/clients/domain/usecases/update_client_usecase.dart';

import 'clients_event.dart';
import 'clients_state.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  ClientsBloc({
    required GetClientsUseCase getClientsUseCase,
    required CreateClientUseCase createClientUseCase,
    required UpdateClientUseCase updateClientUseCase,
  })  : _getClientsUseCase = getClientsUseCase,
        _createClientUseCase = createClientUseCase,
        _updateClientUseCase = updateClientUseCase,
        super(const ClientsInitial()) {
    on<ClientsLoaded>(_onClientsLoaded);
    on<ClientCreated>(_onClientCreated);
    on<ClientUpdated>(_onClientUpdated);
  }

  final GetClientsUseCase _getClientsUseCase;
  final CreateClientUseCase _createClientUseCase;
  final UpdateClientUseCase _updateClientUseCase;

  Future<void> _onClientsLoaded(
    ClientsLoaded event,
    Emitter<ClientsState> emit,
  ) async {
    emit(const ClientsLoading());

    final result = await _getClientsUseCase.call();

    result.fold(
      onSuccess: (data) => emit(ClientsLoadedState(
        clients: data.clients,
        total: data.total,
        limit: data.limit,
        offset: data.offset,
      )),
      onFailure: (f) => emit(ClientsError(f.displayMessage)),
    );
  }

  Future<void> _reloadClientsAndEmit(Emitter<ClientsState> emit) async {
    final listResult = await _getClientsUseCase.call();
    listResult.fold(
      onSuccess: (data) => emit(
        ClientsLoadedState(
          clients: data.clients,
          total: data.total,
          limit: data.limit,
          offset: data.offset,
        ),
      ),
      onFailure: (f) => emit(ClientsError(f.displayMessage)),
    );
  }

  Future<void> _onClientCreated(
    ClientCreated event,
    Emitter<ClientsState> emit,
  ) async {
    final result = await _createClientUseCase.call(
      name: event.name,
      identifier: event.identifier,
      taxId: event.taxId,
      email: event.email,
      phone: event.phone,
      address: event.address,
    );

    await result.when<Future<void>>(
      success: (_) async => await _reloadClientsAndEmit(emit),
      failure: (f) async => emit(ClientsError(f.displayMessage)),
    );
  }

  Future<void> _onClientUpdated(
    ClientUpdated event,
    Emitter<ClientsState> emit,
  ) async {
    final result = await _updateClientUseCase.call(
      id: event.id,
      name: event.name,
      identifier: event.identifier,
      taxId: event.taxId,
      email: event.email,
      phone: event.phone,
      address: event.address,
    );

    await result.when<Future<void>>(
      success: (_) async => await _reloadClientsAndEmit(emit),
      failure: (f) async => emit(ClientsError(f.displayMessage)),
    );
  }
}
