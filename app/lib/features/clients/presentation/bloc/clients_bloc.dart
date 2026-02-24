import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/clients/domain/usecases/get_clients_usecase.dart';

import 'clients_event.dart';
import 'clients_state.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  ClientsBloc({
    required GetClientsUseCase getClientsUseCase,
  })  : _getClientsUseCase = getClientsUseCase,
        super(const ClientsInitial()) {
    on<ClientsLoaded>(_onClientsLoaded);
  }

  final GetClientsUseCase _getClientsUseCase;

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
}
