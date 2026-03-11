import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/sales/domain/entities/sale_line_entity.dart';
import 'package:app/features/sales/presentation/bloc/sale_bloc.dart';
import 'package:app/features/sales/presentation/bloc/sale_event.dart';
import 'package:app/features/sales/presentation/bloc/sale_state.dart';

class SaleCartList extends StatelessWidget {
  const SaleCartList({super.key, required this.state});

  final SaleLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.cart.isEmpty) {
      return Center(
        child: Text(
          'No hay productos en la venta',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: state.cart.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final SaleLineEntity line = state.cart[index];
        final lineTotal = line.lineTotalWithTax;
        return Card(
          key: ValueKey(line.item.id),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.item.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RD\$ ${line.unitPrice.toStringAsFixed(2)} c/u (sin ITBIS)',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (line.taxPercentage > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'ITBIS ${line.taxPercentage.toStringAsFixed(2)}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => context.read<SaleBloc>().add(
                        SaleProductQuantityChanged(
                          itemId: line.item.id,
                          quantity: line.quantity - 1,
                        ),
                      ),
                ),
                Text(
                  '${line.quantity}',
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => context.read<SaleBloc>().add(
                        SaleProductQuantityChanged(
                          itemId: line.item.id,
                          quantity: line.quantity + 1,
                        ),
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RD\$ ${lineTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => context
                      .read<SaleBloc>()
                      .add(SaleProductRemoved(line.item.id)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
