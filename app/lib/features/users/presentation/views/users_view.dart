import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/widgets/error_with_retry.dart';
import 'package:app/features/users/domain/entities/local_user_entity.dart';
import 'package:app/features/users/presentation/bloc/users_bloc.dart';
import 'package:app/features/users/presentation/bloc/users_event.dart';
import 'package:app/features/users/presentation/bloc/users_state.dart';
import 'package:app/features/users/presentation/widgets/user_form_bottom_sheet.dart';
import 'package:app/features/users/presentation/widgets/user_list_widget.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: BlocBuilder<UsersBloc, UsersState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          if (state is UsersLoading || state is UsersInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UsersError) {
            return ErrorWithRetry(
              message: state.message,
              onRetry: () => context.read<UsersBloc>().add(const UsersLoaded()),
            );
          }
          if (state is UsersLoadedState) {
            final bloc = context.read<UsersBloc>();
            return UserListWidget(
              users: state.users,
              onUserTap: (user) => _openEditSheet(context, bloc, user),
              onDeleteTap: (user) => _confirmDelete(context, bloc, user),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, context.read<UsersBloc>()),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Nuevo usuario'),
      ),
    );
  }

  void _openCreateSheet(BuildContext context, UsersBloc bloc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => UserFormBottomSheet(
        onCreate:
            ({
              required String username,
              required String email,
              required String password,
              required String role,
            }) {
              bloc.add(
                UserCreated(
                  username: username,
                  email: email,
                  password: password,
                  role: role,
                ),
              );
              Navigator.of(ctx).pop();
            },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openEditSheet(
    BuildContext context,
    UsersBloc bloc,
    LocalUserEntity user,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => UserFormBottomSheet(
        initialUser: user,
        onUpdate:
            ({
              required int id,
              required String username,
              required String email,
              String? password,
              required String role,
            }) {
              bloc.add(
                UserUpdated(
                  id: id,
                  username: username,
                  email: email,
                  password: password,
                  role: role,
                ),
              );
              Navigator.of(ctx).pop();
            },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UsersBloc bloc,
    LocalUserEntity user,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('Se eliminara a ${user.username}. Desea continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      bloc.add(UserDeleted(user.id));
    }
  }
}
