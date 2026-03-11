import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/sales/domain/entities/sale_line_entity.dart';
import 'package:app/features/sales/presentation/bloc/sale_bloc.dart';
import 'package:app/features/sales/presentation/bloc/sale_event.dart';
import 'package:app/features/sales/presentation/bloc/sale_state.dart';

class SaleView extends StatefulWidget {
  const SaleView({super.key});

  @override
  State<SaleView> createState() => _SaleViewState();
}

class _SaleViewState extends State<SaleView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cashGivenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SaleBloc>().add(const SaleInitialized());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cashGivenController.dispose();
    super.dispose();
  }

  void _onSubmitSale(SaleLoaded state) {
    context.read<SaleBloc>().add(const SaleSubmitted());

    if (state.cart.isEmpty || state.cashGiven < state.totalAmount) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Venta registrada'),
          content: Text(
            'Subtotal: ${state.subtotal.toStringAsFixed(2)}\n'
            'ITBIS: ${state.taxAmount.toStringAsFixed(2)}\n'
            'Total: ${state.totalAmount.toStringAsFixed(2)}\n'
            'Efectivo: ${state.cashGiven.toStringAsFixed(2)}\n'
            'Cambio: ${state.change.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta'),
      ),
      body: BlocBuilder<SaleBloc, SaleState>(
        builder: (context, state) {
          if (state is SaleLoading || state is SaleInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SaleError) {
            return Center(
              child: Text(state.message),
            );
          }
          final loaded = state as SaleLoaded;
          final isValidSale =
              loaded.cart.isNotEmpty && loaded.cashGiven >= loaded.totalAmount;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar producto',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => context
                            .read<SaleBloc>()
                            .add(SaleSearchQueryChanged(value)),
                      ),
                    ),
                    if (loaded.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            loaded.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: _buildSearchResults(theme, loaded),
                    ),
                  ],
                ),
              ),
              Container(
                width: 360,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Detalle de venta',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildCart(theme, loaded),
                    ),
                    const Divider(height: 1),
                    _buildTotalsSection(theme, loaded, isValidSale),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, SaleLoaded state) {
    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Text(
          'Busca un producto para iniciar la venta',
          style: theme.textTheme.bodyMedium,
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

  Widget _buildCart(ThemeData theme, SaleLoaded state) {
    if (state.cart.isEmpty) {
      return Center(
        child: Text(
          'No hay productos en la venta',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: state.cart.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final SaleLineEntity line = state.cart[index];
        final lineTotal = line.lineTotalWithTax;
        return Card(
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
                  onPressed: () =>
                      context.read<SaleBloc>().add(SaleProductQuantityChanged(
                            itemId: line.item.id,
                            quantity: line.quantity - 1,
                          )),
                ),
                Text(
                  '${line.quantity}',
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () =>
                      context.read<SaleBloc>().add(SaleProductQuantityChanged(
                            itemId: line.item.id,
                            quantity: line.quantity + 1,
                          )),
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

  Widget _buildTotalsSection(
    ThemeData theme,
    SaleLoaded state,
    bool isValidSale,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'RD\$ ${state.subtotal.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITBIS',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'RD\$ ${state.taxAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total a pagar',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'RD\$ ${state.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cashGivenController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Efectivo recibido',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(
                          value.replaceAll(',', '.'),
                        ) ??
                        0;
                    context
                        .read<SaleBloc>()
                        .add(SaleCashGivenChanged(parsed));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Cambio',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'RD\$ ${state.change <= 0 ? '0.00' : state.change.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isValidSale && !state.isSubmitting
                  ? () => _onSubmitSale(state)
                  : null,
              icon: const Icon(Icons.point_of_sale_rounded),
              label: Text(
                state.isSubmitting ? 'Facturando' : 'Facturar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}


