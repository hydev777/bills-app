import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/widgets/error_with_retry.dart';
import 'package:app/features/bills/presentation/bloc/bills_bloc.dart';
import 'package:app/features/bills/presentation/bloc/bills_event.dart';
import 'package:app/features/bills/presentation/bloc/bills_state.dart';
import 'package:app/features/bills/presentation/widgets/bills_list_widget.dart';
import 'package:app/features/bills/presentation/widgets/bills_search_bar.dart';

class BillsView extends StatelessWidget {
  const BillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas'),
      ),
      body: BlocBuilder<BillsBloc, BillsState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          if (state is BillsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BillsError) {
            return ErrorWithRetry(
              message: state.message,
              onRetry: () =>
                  context.read<BillsBloc>().add(const BillsLoaded()),
            );
          }
          if (state is BillsLoadedState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BillsSearchBar(
                  onSearch: (query) => context
                      .read<BillsBloc>()
                      .add(BillSearchRequested(query)),
                  onClear: () =>
                      context.read<BillsBloc>().add(const BillsLoaded()),
                ),
                Expanded(
                  child: BillsListWidget(bills: state.bills),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

