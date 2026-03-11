import 'package:equatable/equatable.dart';

import 'package:app/features/products/domain/entities/item_entity.dart';

class SaleLineEntity extends Equatable {
  const SaleLineEntity({
    required this.item,
    required this.quantity,
    required this.unitPrice,
  });

  final ItemEntity item;
  final int quantity;
  final double unitPrice;

  /// Porcentaje de ITBIS del producto (0 si no viene definido).
  double get taxPercentage => item.itbisPercentage ?? 0;

  /// Subtotal de la línea sin ITBIS.
  double get lineSubtotal => unitPrice * quantity;

  /// ITBIS de la línea.
  double get lineTax => lineSubtotal * (taxPercentage / 100);

  /// Total de la línea incluyendo ITBIS.
  double get lineTotalWithTax => lineSubtotal + lineTax;

  SaleLineEntity copyWith({
    ItemEntity? item,
    int? quantity,
    double? unitPrice,
  }) {
    return SaleLineEntity(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  List<Object?> get props => [item, quantity, unitPrice];
}

