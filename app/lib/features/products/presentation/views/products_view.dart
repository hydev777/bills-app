import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/products/presentation/bloc/products_bloc.dart';
import 'package:app/features/products/presentation/bloc/products_event.dart';
import 'package:app/features/products/presentation/bloc/products_state.dart';
import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/core/widgets/error_with_retry.dart';
import 'package:app/features/products/presentation/widgets/product_form_widget.dart';
import 'package:app/features/products/presentation/widgets/product_list_widget.dart';
import 'package:app/injection.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  @override
  void initState() {
    super.initState();
    sl<ProductsBloc>().add(const ProductsLoaded());
  }

  void _openCreateSheet(BuildContext context, ProductsLoadedState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProductFormWidget(
        categories: state.categories,
        itbisRates: state.itbisRates,
        onCreate: ({
          required String name,
          String? description,
          required double unitPrice,
          int? categoryId,
          required int itbisRateId,
        }) {
          sl<ProductsBloc>().add(ProductCreateRequested(
            name: name,
            description: description,
            unitPrice: unitPrice,
            categoryId: categoryId,
            itbisRateId: itbisRateId,
          ));
          Navigator.of(ctx).pop();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openEditSheet(BuildContext context, ItemEntity item) {
    final state = context.read<ProductsBloc>().state;
    if (state is! ProductsLoadedState && state is! ProductsUpdateLoading) return;
    final categories = state is ProductsLoadedState ? state.categories : (state as ProductsUpdateLoading).categories;
    final itbisRates = state is ProductsLoadedState ? state.itbisRates : (state as ProductsUpdateLoading).itbisRates;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProductFormWidget(
        initialItem: item,
        categories: categories,
        itbisRates: itbisRates,
        onUpdate: ({
          required int id,
          required String name,
          String? description,
          required double unitPrice,
          int? categoryId,
          required int itbisRateId,
        }) {
          sl<ProductsBloc>().add(ProductUpdateRequested(
            id: id,
            name: name,
            description: description,
            unitPrice: unitPrice,
            categoryId: categoryId,
            itbisRateId: itbisRateId,
          ));
          Navigator.of(ctx).pop();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ProductsBloc>(),
      child: Scaffold(
        body: BlocBuilder<ProductsBloc, ProductsState>(
          buildWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType,
          builder: (context, state) {
            if (state is ProductsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductsError) {
              return ErrorWithRetry(
                message: state.message,
                onRetry: () =>
                    context.read<ProductsBloc>().add(const ProductsLoaded()),
              );
            }
            if (state is ProductsCreateLoading || state is ProductsUpdateLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductsLoadedState) {
              return ProductListWidget(
                items: state.items,
                onProductTap: (item) => _openEditSheet(context, item),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: BlocSelector<ProductsBloc, ProductsState, bool>(
          selector: (state) =>
              state is ProductsLoadedState && state.itbisRates.isNotEmpty,
          builder: (context, showFab) {
            if (!showFab) return const SizedBox.shrink();
            final state = context.read<ProductsBloc>().state;
            if (state is! ProductsLoadedState) return const SizedBox.shrink();
            final theme = Theme.of(context);
            return FloatingActionButton.extended(
              onPressed: () => _openCreateSheet(context, state),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo producto'),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              elevation: 2,
            );
          },
        ),
      ),
    );
  }
}
