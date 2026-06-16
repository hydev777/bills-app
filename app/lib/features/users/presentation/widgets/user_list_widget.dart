import 'package:flutter/material.dart';

import 'package:app/features/users/domain/entities/local_user_entity.dart';

class UserListWidget extends StatelessWidget {
  const UserListWidget({
    super.key,
    required this.users,
    required this.onUserTap,
    required this.onDeleteTap,
  });

  final List<LocalUserEntity> users;
  final void Function(LocalUserEntity user) onUserTap;
  final void Function(LocalUserEntity user) onDeleteTap;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No hay usuarios creados'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            onTap: () => onUserTap(user),
            leading: CircleAvatar(
              child: Text(user.username.characters.first.toUpperCase()),
            ),
            title: Text(user.username),
            subtitle: Text(_roleLabel(user.role)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onDeleteTap(user),
            ),
          ),
        );
      },
    );
  }
}

String _roleLabel(String role) {
  switch (role.toLowerCase()) {
    case 'administrador':
      return 'Administrador';
    case 'cajero':
      return 'Cajero';
    default:
      return 'Usuario';
  }
}
