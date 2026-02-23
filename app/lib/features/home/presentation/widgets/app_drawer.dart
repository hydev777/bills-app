import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/injection.dart';

import 'home_menu_entries.dart';

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
                homeMenuTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          HomeMenuContent(
            currentPath: GoRouterState.of(context).uri.path,
            onNavigate: (path) {
              Navigator.of(context).pop();
              context.go(path);
            },
            onLogout: () {
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
