import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/injection.dart';

import 'home_menu_entries.dart';

/// Left sidebar menu, always visible in the dashboard.
class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key});

  static const double width = 260;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = colorScheme.surfaceContainerLowest;
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 28,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    homeMenuTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          HomeMenuContent(
            currentPath: currentPath,
            onNavigate: (path) => context.go(path),
            onLogout: () {
              sl<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
