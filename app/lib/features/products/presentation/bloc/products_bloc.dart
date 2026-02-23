import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/products/domain/usecases/create_item_usecase.dart';
import 'package:app/features/products/domain/usecases/get_categories_usecase.dart';
import 'package:app/features/products/domain/usecases/get_itbis_rates_usecase.dart';
import 'package:app/features/products/domain/usecases/get_items_usecase.dart';

import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({
    required GetItemsUseCase getItemsUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
    required GetItbisRatesUseCase getItbisRatesUseCase,
    required CreateItemUseCase createItemUseCase,
  })  : _getItemsUseCase = getItemsUseCase,
        _getCategoriesUseCase = getCategoriesUseCase,
        _getItbisRatesUseCase = getItbisRatesUseCase,
        _createItemUseCase = createItemUseCase,
        super(const ProductsInitial()) {
    on<ProductsLoaded>(_onProductsLoaded);
    on<ProductCreateRequested>(_onProductCreateRequested);
  }

  final GetItemsUseCase _getItemsUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetItbisRatesUseCase _getItbisRatesUseCase;
  final CreateItemUseCase _createItemUseCase;

  Future<void> _onProductsLoaded(
    ProductsLoaded event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductsLoading());
    final itemsResult = await _getItemsUseCase.call();
    final categoriesResult = await _getCategoriesUseCase.call();
    final itbisResult = await _getItbisRatesUseCase.call();

    final items = itemsResult.valueOrNull;
    final categories = categoriesResult.valueOrNull;
    final itbisRates = itbisResult.valueOrNull;

    final failure = itemsResult.errorOrNull ?? categoriesResult.errorOrNull ?? itbisResult.errorOrNull;
    if (failure != null) {
      emit(ProductsError(failure.displayMessage));
      return;
    }
    if (items == null || categories == null || itbisRates == null) {
      emit(const ProductsError('Error al cargar datos'));
      return;
    }

    emit(ProductsLoadedState(
      items: items.items,
      total: items.total,
      categories: categories,
      itbisRates: itbisRates,
    ));
  }

  Future<void> _onProductCreateRequested(
    ProductCreateRequested event,
    Emitter<ProductsState> emit,
  ) async {
    final current = state;
    if (current is! ProductsLoadedState && current is! ProductsCreateLoading) return;

    final items = current is ProductsLoadedState ? current.items : (current as ProductsCreateLoading).items;
    final total = current is ProductsLoadedState ? current.total : (current as ProductsCreateLoading).total;
    final categories = current is ProductsLoadedState ? current.categories : (current as ProductsCreateLoading).categories;
    final itbisRates = current is ProductsLoadedState ? current.itbisRates : (current as ProductsCreateLoading).itbisRates;

    emit(ProductsCreateLoading(
      items: items,
      total: total,
      categories: categories,
      itbisRates: itbisRates,
    ));

    final result = await _createItemUseCase.call(
      name: event.name,
      description: event.description,
      unitPrice: event.unitPrice,
      categoryId: event.categoryId,
      itbisRateId: event.itbisRateId,
    );

    result.fold(
      onSuccess: (_) => add(const ProductsLoaded()),
      onFailure: (f) => emit(ProductsError(f.displayMessage)),
    );
  }
}
