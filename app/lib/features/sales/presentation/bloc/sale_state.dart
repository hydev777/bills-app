import 'package:equatable/equatable.dart';

import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/sales/domain/entities/sale_line_entity.dart';

sealed class SaleState extends Equatable {
  const SaleState();

  @override
  List<Object?> get props => [];
}

final class SaleInitial extends SaleState {
  const SaleInitial();
}

final class SaleLoading extends SaleState {
  const SaleLoading();
}

final class SaleLoaded extends SaleState {
  const SaleLoaded({
    required this.searchQuery,
    required this.searchResults,
    required this.cart,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.cashGiven,
    required this.change,
    this.isSearching = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String searchQuery;
  final List<ItemEntity> searchResults;
  final List<SaleLineEntity> cart;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double cashGiven;
  final double change;
  final bool isSearching;
  final bool isSubmitting;
  final String? errorMessage;

  SaleLoaded copyWith({
    String? searchQuery,
    List<ItemEntity>? searchResults,
    List<SaleLineEntity>? cart,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    double? cashGiven,
    double? change,
    bool? isSearching,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return SaleLoaded(
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      cart: cart ?? this.cart,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      cashGiven: cashGiven ?? this.cashGiven,
      change: change ?? this.change,
      isSearching: isSearching ?? this.isSearching,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        searchResults,
        cart,
        subtotal,
        taxAmount,
        totalAmount,
        cashGiven,
        change,
        isSearching,
        isSubmitting,
        errorMessage,
      ];
}

final class SaleError extends SaleState {
  const SaleError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

