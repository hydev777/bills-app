import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/widgets/error_with_retry.dart';
import 'package:app/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:app/features/clients/presentation/bloc/clients_event.dart';
import 'package:app/features/clients/presentation/bloc/clients_state.dart';
import 'package:app/features/clients/domain/entities/client_entity.dart';
import 'package:app/features/clients/presentation/widgets/client_form_bottom_sheet.dart';
import 'package:app/features/clients/presentation/widgets/client_list_widget.dart';

class ClientsView extends StatelessWidget {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body: BlocBuilder<ClientsBloc, ClientsState>(
        buildWhen: (previous, current) => previous != current,
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
            final bloc = context.read<ClientsBloc>();
            return ClientListWidget(
              clients: state.clients,
              onClientTap: (client) => _openEditSheet(context, bloc, client),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final bloc = context.read<ClientsBloc>();
          _openCreateSheet(context, bloc);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo cliente'),
      ),
    );
  }

  void _openCreateSheet(BuildContext context, ClientsBloc bloc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return ClientFormBottomSheet(
          onCreate: ({
            required String name,
            String? identifier,
            String? taxId,
            String? email,
            String? phone,
            String? address,
          }) {
            bloc.add(
              ClientCreated(
                name: name,
                identifier: identifier,
                taxId: taxId,
                email: email,
                phone: phone,
                address: address,
              ),
            );
            Navigator.of(ctx).pop();
          },
          onCancel: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  void _openEditSheet(
    BuildContext context,
    ClientsBloc bloc,
    ClientEntity client,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return ClientFormBottomSheet(
          initialClient: client,
          onUpdate: ({
            required int id,
            required String name,
            String? identifier,
            String? taxId,
            String? email,
            String? phone,
            String? address,
          }) {
            bloc.add(
              ClientUpdated(
                id: id,
                name: name,
                identifier: identifier,
                taxId: taxId,
                email: email,
                phone: phone,
                address: address,
              ),
            );
            Navigator.of(ctx).pop();
          },
          onCancel: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }
}
