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
