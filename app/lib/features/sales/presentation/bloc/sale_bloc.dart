import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/errors/failures.dart';
import 'package:app/features/bills/domain/entities/bill_entity.dart';
import 'package:app/features/bills/domain/usecases/create_sale_bill_usecase.dart';
import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/products/domain/usecases/get_items_usecase.dart';
import 'package:app/features/sales/domain/entities/sale_line_entity.dart';

import 'sale_event.dart';
import 'sale_state.dart';

class SaleBloc extends Bloc<SaleEvent, SaleState> {
  SaleBloc({
    required GetItemsUseCase getItemsUseCase,
    required CreateSaleBillUseCase createSaleBillUseCase,
  })  : _getItemsUseCase = getItemsUseCase,
        _createSaleBillUseCase = createSaleBillUseCase,
        super(const SaleInitial()) {
    on<SaleInitialized>(_onInitialized);
    on<SaleSearchQueryChanged>(_onSearchQueryChanged);
    on<SaleProductAdded>(_onProductAdded);
    on<SaleProductQuantityChanged>(_onProductQuantityChanged);
    on<SaleProductRemoved>(_onProductRemoved);
    on<SaleCashGivenChanged>(_onCashGivenChanged);
    on<SaleSubmitted>(_onSubmitted);
    on<SaleSuccessDialogDismissed>(_onSuccessDialogDismissed);
  }

  final GetItemsUseCase _getItemsUseCase;
  final CreateSaleBillUseCase _createSaleBillUseCase;

  Future<void> _onInitialized(
    SaleInitialized event,
    Emitter<SaleState> emit,
  ) async {
    emit(
      const SaleLoaded(
        searchQuery: '',
        searchResults: <ItemEntity>[],
        cart: <SaleLineEntity>[],
        subtotal: 0,
        taxAmount: 0,
        totalAmount: 0,
        cashGiven: 0,
        change: 0,
      ),
    );
  }

  Future<void> _onSearchQueryChanged(
    SaleSearchQueryChanged event,
    Emitter<SaleState> emit,
  ) async {
    final current = state;
    if (current is! SaleLoaded) return;

    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        current.copyWith(
          searchQuery: '',
          searchResults: <ItemEntity>[],
          isSearching: false,
          errorMessage: null,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        searchQuery: query,
        isSearching: true,
        errorMessage: null,
      ),
    );

    final result = await _getItemsUseCase.call(
      search: query,
      limit: 20,
      offset: 0,
    );

    final failure = result.errorOrNull;
    final itemsResult = result.valueOrNull;

    if (failure != null || itemsResult == null) {
      emit(
        current.copyWith(
          isSearching: false,
          errorMessage: failure?.displayMessage ?? 'Error al buscar productos',
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        isSearching: false,
        searchResults: itemsResult.items,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onProductAdded(
    SaleProductAdded event,
    Emitter<SaleState> emit,
  ) async {
    final current = state;
    if (current is! SaleLoaded) return;

    final cart = List<SaleLineEntity>.from(current.cart);
    final index = cart.indexWhere((line) => line.item.id == event.item.id);
    if (index >= 0) {
      final existing = cart[index];
      cart[index] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      cart.add(
        SaleLineEntity(
          item: event.item,
          quantity: 1,
          unitPrice: event.item.unitPrice,
        ),
      );
    }

    final subtotal = _calculateSubtotal(cart);
    final taxAmount = _calculateTax(cart);
    final totalAmount = _calculateTotal(subtotal, taxAmount);
    final change = _calculateChange(totalAmount, current.cashGiven);

    emit(
      current.copyWith(
        cart: cart,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        change: change,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onProductQuantityChanged(
    SaleProductQuantityChanged event,
    Emitter<SaleState> emit,
  ) async {
    final current = state;
    if (current is! SaleLoaded) return;

    final cart = List<SaleLineEntity>.from(current.cart);
    final index = cart.indexWhere((line) => line.item.id == event.itemId);
    if (index < 0) return;

    if (event.quantity <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = cart[index].copyWith(quantity: event.quantity);
    }

    final subtotal = _calculateSubtotal(cart);
    final taxAmount = _calculateTax(cart);
    final totalAmount = _calculateTotal(subtotal, taxAmount);
    final change = _calculateChange(totalAmount, current.cashGiven);

    emit(
      current.copyWith(
        cart: cart,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        change: change,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onProductRemoved(
    SaleProductRemoved event,
    Emitter<SaleState> emit,
  ) async {
    final current = state;
    if (current is! SaleLoaded) return;

    final cart = current.cart
        .where((line) => line.item.id != event.itemId)
        .toList(growable: false);

    final subtotal = _calculateSubtotal(cart);
    final taxAmount = _calculateTax(cart);
    final totalAmount = _calculateTotal(subtotal, taxAmount);
    final change = _calculateChange(totalAmount, current.cashGiven);

    emit(
      current.copyWith(
        cart: cart,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        change: change,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onCashGivenChanged(
    SaleCashGivenChanged event,
    Emitter<SaleState> emit,
  ) async {
    final current = state;
    if (current is! SaleLoaded) return;

    final double cashGiven = event.cashGiven < 0 ? 0 : event.cashGiven;
    final double change = _calculateChange(current.totalAmount, cashGiven);

    emit(
      current.copyWith(
        cashGiven: cashGiven,
        change: change,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onSubmitted(
    SaleSubmitted event,
    Emitter<SaleState> emit,
  ) async {
    final current = state;
    if (current is! SaleLoaded) return;

    if (current.cart.isEmpty) {
      emit(
        current.copyWith(
          errorMessage: 'Agrega al menos un producto a la venta',
        ),
      );
      return;
    }
    if (current.cashGiven < current.totalAmount) {
      emit(
        current.copyWith(
          errorMessage: 'El efectivo es menor que el total',
        ),
      );
      return;
    }

    emit(current.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _createSaleBillUseCase.call(
      lines: current.cart,
      cashGiven: current.cashGiven,
      subtotal: current.subtotal,
    );

    await result.when<Future<void>>(
      success: (BillEntity _) async {
        final summary = SaleSuccessSummary(
          subtotal: current.subtotal,
          taxAmount: current.taxAmount,
          totalAmount: current.totalAmount,
          cashGiven: current.cashGiven,
          change: current.change,
        );
        emit(
          SaleLoaded(
            searchQuery: '',
            searchResults: <ItemEntity>[],
            cart: const <SaleLineEntity>[],
            subtotal: 0,
            taxAmount: 0,
            totalAmount: 0,
            cashGiven: 0,
            change: 0,
            successSummaryToShow: summary,
          ),
        );
      },
      failure: (Failure f) async {
        emit(
          current.copyWith(
            isSubmitting: false,
            errorMessage: f.displayMessage,
          ),
        );
      },
    );
  }

  double _calculateSubtotal(List<SaleLineEntity> cart) {
    return cart.fold<double>(
      0.0,
      (sum, line) => sum + line.lineSubtotal,
    );
  }

  double _calculateTax(List<SaleLineEntity> cart) {
    return cart.fold<double>(
      0.0,
      (sum, line) => sum + line.lineTax,
    );
  }

  double _calculateTotal(double subtotal, double taxAmount) {
    return subtotal + taxAmount;
  }

  double _calculateChange(double totalAmount, double cashGiven) {
    final change = cashGiven - totalAmount;
    return change > 0 ? change : 0;
  }

  void _onSuccessDialogDismissed(
    SaleSuccessDialogDismissed event,
    Emitter<SaleState> emit,
  ) {
    final current = state;
    if (current is SaleLoaded) {
      emit(current.copyWith(clearSuccessSummary: true));
    }
  }
}

