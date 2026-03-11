import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/sales/presentation/bloc/sale_bloc.dart';
import 'package:app/features/sales/presentation/bloc/sale_event.dart';
import 'package:app/features/sales/presentation/bloc/sale_state.dart';

class SaleTotalsSection extends StatelessWidget {
  const SaleTotalsSection({
    super.key,
    required this.state,
    required this.cashGivenController,
    required this.onSubmitSale,
  });

  final SaleLoaded state;
  final TextEditingController cashGivenController;
  final VoidCallback onSubmitSale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValidSale = state.cart.isNotEmpty &&
        state.cashGiven >= state.totalAmount &&
        !state.isSubmitting;

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
                  controller: cashGivenController,
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
              onPressed: isValidSale ? onSubmitSale : null,
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
