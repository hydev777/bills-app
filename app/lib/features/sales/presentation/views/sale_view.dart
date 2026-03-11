import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/sales/presentation/bloc/sale_bloc.dart';
import 'package:app/features/sales/presentation/bloc/sale_event.dart';
import 'package:app/features/sales/presentation/bloc/sale_state.dart';
import 'package:app/features/sales/presentation/widgets/sale_cart_list.dart';
import 'package:app/features/sales/presentation/widgets/sale_search_results.dart';
import 'package:app/features/sales/presentation/widgets/sale_totals_section.dart';

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

  void _onSubmitSale() {
    context.read<SaleBloc>().add(const SaleSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta'),
      ),
      body: BlocListener<SaleBloc, SaleState>(
        listenWhen: (previous, current) =>
            current is SaleLoaded &&
            current.successSummaryToShow != null,
        listener: (context, state) {
          final loaded = state as SaleLoaded;
          final summary = loaded.successSummaryToShow!;
          showDialog<void>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Venta registrada'),
                content: Text(
                  'Subtotal: ${summary.subtotal.toStringAsFixed(2)}\n'
                  'ITBIS: ${summary.taxAmount.toStringAsFixed(2)}\n'
                  'Total: ${summary.totalAmount.toStringAsFixed(2)}\n'
                  'Efectivo: ${summary.cashGiven.toStringAsFixed(2)}\n'
                  'Cambio: ${summary.change.toStringAsFixed(2)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      context
                          .read<SaleBloc>()
                          .add(const SaleSuccessDialogDismissed());
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            },
          );
        },
        child: BlocBuilder<SaleBloc, SaleState>(
          buildWhen: (previous, current) {
            if (previous.runtimeType != current.runtimeType) return true;
            if (current is SaleLoaded && previous is SaleLoaded) {
              return previous.isSearching != current.isSearching ||
                  previous.searchResults != current.searchResults ||
                  previous.searchQuery != current.searchQuery ||
                  previous.cart != current.cart ||
                  previous.subtotal != current.subtotal ||
                  previous.taxAmount != current.taxAmount ||
                  previous.totalAmount != current.totalAmount ||
                  previous.cashGiven != current.cashGiven ||
                  previous.change != current.change ||
                  previous.isSubmitting != current.isSubmitting ||
                  previous.errorMessage != current.errorMessage;
            }
            return true;
          },
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
                        child: SaleSearchResults(state: loaded),
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
                        color: theme
                            .colorScheme.outlineVariant.withOpacity(0.4),
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
                        child: SaleCartList(state: loaded),
                      ),
                      const Divider(height: 1),
                      SaleTotalsSection(
                        state: loaded,
                        cashGivenController: _cashGivenController,
                        onSubmitSale: _onSubmitSale,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
