import 'package:equatable/equatable.dart';

sealed class BillsEvent extends Equatable {
  const BillsEvent();

  @override
  List<Object?> get props => [];
}

/// Load bills list (on open / refresh).
final class BillsLoaded extends BillsEvent {
  const BillsLoaded({
    this.status,
    this.userId,
    this.clientId,
    this.limit = 50,
    this.offset = 0,
  });

  final String? status;
  final int? userId;
  final int? clientId;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [status, userId, clientId, limit, offset];
}

/// Search a bill by id or public id.
final class BillSearchRequested extends BillsEvent {
  const BillSearchRequested(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

