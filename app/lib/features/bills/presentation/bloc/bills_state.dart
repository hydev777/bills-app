import 'package:equatable/equatable.dart';

import 'package:app/features/bills/domain/entities/bill_entity.dart';

sealed class BillsState extends Equatable {
  const BillsState();

  @override
  List<Object?> get props => [];
}

final class BillsInitial extends BillsState {
  const BillsInitial();
}

final class BillsLoading extends BillsState {
  const BillsLoading();
}

final class BillsLoadedState extends BillsState {
  const BillsLoadedState({
    required this.bills,
    required this.total,
    required this.limit,
    required this.offset,
    this.activeSearchQuery,
  });

  final List<BillEntity> bills;
  final int total;
  final int limit;
  final int offset;
  final String? activeSearchQuery;

  @override
  List<Object?> get props => [bills, total, limit, offset, activeSearchQuery];
}

final class BillsError extends BillsState {
  const BillsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

