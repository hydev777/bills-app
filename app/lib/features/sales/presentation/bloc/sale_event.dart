import 'package:equatable/equatable.dart';

import 'package:app/features/products/domain/entities/item_entity.dart';

sealed class SaleEvent extends Equatable {
  const SaleEvent();

  @override
  List<Object?> get props => [];
}

final class SaleInitialized extends SaleEvent {
  const SaleInitialized();
}

final class SaleSearchQueryChanged extends SaleEvent {
  const SaleSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SaleProductAdded extends SaleEvent {
  const SaleProductAdded(this.item);

  final ItemEntity item;

  @override
  List<Object?> get props => [item];
}

final class SaleProductQuantityChanged extends SaleEvent {
  const SaleProductQuantityChanged({
    required this.itemId,
    required this.quantity,
  });

  final int itemId;
  final int quantity;

  @override
  List<Object?> get props => [itemId, quantity];
}

final class SaleProductRemoved extends SaleEvent {
  const SaleProductRemoved(this.itemId);

  final int itemId;

  @override
  List<Object?> get props => [itemId];
}

final class SaleCashGivenChanged extends SaleEvent {
  const SaleCashGivenChanged(this.cashGiven);

  final double cashGiven;

  @override
  List<Object?> get props => [cashGiven];
}

final class SaleSubmitted extends SaleEvent {
  const SaleSubmitted();
}

