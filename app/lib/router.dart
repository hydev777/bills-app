import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import 'package:app/features/auth/presentation/views/login_view.dart';
import 'package:app/features/home/presentation/views/home_shell_view.dart';
import 'package:app/features/home/presentation/views/placeholder_view.dart';
import 'package:app/injection.dart';

/// Listenable that notifies when [AuthBloc] state changes so GoRouter can re-run redirect.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._bloc) {
    _bloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _bloc;
}

late final GoRouter appRouter;

void initRouter() {
  final authBloc = sl<AuthBloc>();
  final refreshNotifier = _AuthRefreshNotifier(authBloc);

  appRouter = GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;
      final isAuthenticated = authState is AuthAuthenticated;

      if (isAuthenticated && (location == '/' || location == '/login')) {
        return '/home/facturas';
      }
      if (!isAuthenticated && location.startsWith('/home')) {
        return '/login';
      }
      if (location == '/') {
        return '/login'; // If authenticated, first if would have returned
      }
      if (isAuthenticated && location == '/home') {
        return '/home/facturas';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShellView(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              GoRoute(
                path: 'facturas',
                builder: (context, state) =>
                    const PlaceholderView(title: 'Facturas'),
              ),
              GoRoute(
                path: 'clientes',
                builder: (context, state) =>
                    const PlaceholderView(title: 'Clientes'),
              ),
              GoRoute(
                path: 'productos',
                builder: (context, state) =>
                    const PlaceholderView(title: 'Productos'),
              ),
              GoRoute(
                path: 'categorias',
                builder: (context, state) =>
                    const PlaceholderView(title: 'Categorías'),
              ),
              GoRoute(
                path: 'sucursales',
                builder: (context, state) =>
                    const PlaceholderView(title: 'Sucursales'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
