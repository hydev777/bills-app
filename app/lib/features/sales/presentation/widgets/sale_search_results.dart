import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/sales/presentation/bloc/sale_bloc.dart';
import 'package:app/features/sales/presentation/bloc/sale_event.dart';
import 'package:app/features/sales/presentation/bloc/sale_state.dart';

class SaleSearchResults extends StatelessWidget {
  const SaleSearchResults({super.key, required this.state});

  final SaleLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Text(
          'Busca un producto para iniciar la venta',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: state.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ItemEntity item = state.searchResults[index];
        return ListTile(
          key: ValueKey(item.id),
          title: Text(item.name),
          subtitle: Text('RD\$ ${item.unitPrice.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: () =>
                context.read<SaleBloc>().add(SaleProductAdded(item)),
          ),
        );
      },
    );
  }
}
