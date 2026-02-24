import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/widgets/error_with_retry.dart';
import 'package:app/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:app/features/clients/presentation/bloc/clients_event.dart';
import 'package:app/features/clients/presentation/bloc/clients_state.dart';
import 'package:app/features/clients/presentation/widgets/client_list_widget.dart';
import 'package:app/injection.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  @override
  void initState() {
    super.initState();
    sl<ClientsBloc>().add(const ClientsLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ClientsBloc>(),
      child: Scaffold(
        body: BlocBuilder<ClientsBloc, ClientsState>(
          buildWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType,
          builder: (context, state) {
            if (state is ClientsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ClientsError) {
              return ErrorWithRetry(
                message: state.message,
                onRetry: () =>
                    context.read<ClientsBloc>().add(const ClientsLoaded()),
              );
            }
            if (state is ClientsLoadedState) {
              return ClientListWidget(clients: state.clients);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
