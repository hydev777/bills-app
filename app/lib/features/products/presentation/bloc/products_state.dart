import 'package:equatable/equatable.dart';

import 'package:app/features/products/domain/entities/item_category_entity.dart';
import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/products/domain/entities/itbis_rate_entity.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

final class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

final class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

final class ProductsLoadedState extends ProductsState {
  const ProductsLoadedState({
    required this.items,
    required this.total,
    required this.categories,
    required this.itbisRates,
  });

  final List<ItemEntity> items;
  final int total;
  final List<ItemCategoryEntity> categories;
  final List<ItbisRateEntity> itbisRates;

  @override
  List<Object?> get props => [items, total, categories, itbisRates];
}

final class ProductsCreateLoading extends ProductsState {
  const ProductsCreateLoading({
    required this.items,
    required this.total,
    required this.categories,
    required this.itbisRates,
  });

  final List<ItemEntity> items;
  final int total;
  final List<ItemCategoryEntity> categories;
  final List<ItbisRateEntity> itbisRates;

  @override
  List<Object?> get props => [items, total, categories, itbisRates];
}

final class ProductsUpdateLoading extends ProductsState {
  const ProductsUpdateLoading({
    required this.items,
    required this.total,
    required this.categories,
    required this.itbisRates,
  });

  final List<ItemEntity> items;
  final int total;
  final List<ItemCategoryEntity> categories;
  final List<ItbisRateEntity> itbisRates;

  @override
  List<Object?> get props => [items, total, categories, itbisRates];
}

final class ProductsError extends ProductsState {
  const ProductsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
