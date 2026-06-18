import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/constants/api_constants.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import 'package:app/features/auth/presentation/widgets/login_form.dart';
import 'package:app/features/auth/presentation/widgets/local_admin_setup_form.dart';
import 'package:app/injection.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthSessionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    // Router redirect navigates to /home on AuthAuthenticated
                  },
                  buildWhen: (previous, current) => previous != current,
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return const _LoginLoading();
                    }
                    return _LoginContent(state: state);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLoading extends StatelessWidget {
  const _LoginLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Iniciando sesion...'),
        ],
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bootstrapState = state is AuthBootstrapRequired
        ? state as AuthBootstrapRequired
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Facturacion',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          state is AuthBootstrapRequired
              ? 'Cree el primer administrador local'
              : 'Inicie sesion para continuar',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (state is AuthBootstrapRequired)
          const LocalAdminSetupForm()
        else
          const LoginForm(),
        if (state is AuthError) ...[
          const SizedBox(height: 16),
          Text(
            (state as AuthError).message,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        if (bootstrapState?.message != null) ...[
          const SizedBox(height: 16),
          Text(
            bootstrapState!.message!,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
