import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/injection.dart';

import 'drawer_item_tile.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Facturación',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DrawerItemTile(
            icon: Icons.receipt_long,
            label: 'Facturas',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/home/facturas');
            },
          ),
          DrawerItemTile(
            icon: Icons.people,
            label: 'Clientes',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/home/clientes');
            },
          ),
          DrawerItemTile(
            icon: Icons.inventory_2,
            label: 'Productos',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/home/productos');
            },
          ),
          DrawerItemTile(
            icon: Icons.category,
            label: 'Categorías',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/home/categorias');
            },
          ),
          DrawerItemTile(
            icon: Icons.store,
            label: 'Sucursales',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/home/sucursales');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.of(context).pop();
              sl<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
