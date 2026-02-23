import 'package:equatable/equatable.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Load items list, categories and itbis rates (on open / refresh).
final class ProductsLoaded extends ProductsEvent {
  const ProductsLoaded();
}

/// Submit create product form.
final class ProductCreateRequested extends ProductsEvent {
  const ProductCreateRequested({
    required this.name,
    this.description,
    required this.unitPrice,
    this.categoryId,
    required this.itbisRateId,
  });

  final String name;
  final String? description;
  final double unitPrice;
  final int? categoryId;
  final int itbisRateId;

  @override
  List<Object?> get props => [name, description, unitPrice, categoryId, itbisRateId];
}
