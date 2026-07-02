import 'package:app/features/auth/domain/entities/session.dart';
import 'package:flutter/material.dart';

import 'drawer_item_tile.dart';

/// Menu entries for home navigation (sidebar and drawer).
List<({IconData icon, String label, String path})> homeMenuEntries({
  Session? session,
}) {
  final entries = <({IconData icon, String label, String path})>[
    (icon: Icons.point_of_sale, label: 'Venta', path: '/home/venta'),
    (icon: Icons.receipt_long, label: 'Facturas', path: '/home/facturas'),
    (icon: Icons.bar_chart_rounded, label: 'Reportes', path: '/home/reportes'),
    (icon: Icons.people, label: 'Clientes', path: '/home/clientes'),
    (icon: Icons.inventory_2, label: 'Productos', path: '/home/productos'),
    (icon: Icons.category, label: 'Categorias', path: '/home/categorias'),
  ];
  if (session?.user.role.toLowerCase() == 'administrador') {
    entries.add((
      icon: Icons.settings_outlined,
      label: 'Configuracion',
      path: '/home/configuracion',
    ));
    entries.add((
      icon: Icons.manage_accounts,
      label: 'Usuarios',
      path: '/home/usuarios',
    ));
  }
  return entries;
}

/// Shared drawer header title.
const String homeMenuTitle = 'Facturacion';

/// Builds the list of navigation tiles + divider + logout tile.
/// [onNavigate] is called with the path when an entry is tapped.
/// [onLogout] is called when "Cerrar sesion" is tapped.
/// [currentPath] is used to highlight the active menu entry.
class HomeMenuContent extends StatelessWidget {
  const HomeMenuContent({
    super.key,
    required this.onNavigate,
    required this.onLogout,
    this.session,
    this.currentPath,
  });

  final void Function(String path) onNavigate;
  final VoidCallback onLogout;
  final Session? session;
  final String? currentPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...homeMenuEntries(session: session).map(
          (entry) => DrawerItemTile(
            icon: entry.icon,
            label: entry.label,
            selected:
                currentPath == entry.path ||
                (currentPath ?? '').startsWith('${entry.path}/'),
            onTap: () => onNavigate(entry.path),
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          indent: 24,
          endIndent: 24,
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 22,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Cerrar sesion',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
