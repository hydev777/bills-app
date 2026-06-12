import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/utils/validation.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';

class LocalAdminSetupForm extends StatefulWidget {
  const LocalAdminSetupForm({super.key});

  @override
  State<LocalAdminSetupForm> createState() => _LocalAdminSetupFormState();
}

class _LocalAdminSetupFormState extends State<LocalAdminSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthInitialAdminCreateRequested(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Ingrese un usuario';
              if (text.length < 3) return 'Minimo 3 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Correo electronico',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Ingrese un correo';
              if (!isValidEmail(text)) return 'Ingrese un correo valido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Contrasena',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Ingrese una contrasena';
              if (value.length < 8) return 'Minimo 8 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirmar contrasena',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirme la contrasena';
              }
              if (value != _passwordController.text) {
                return 'Las contrasenas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Crear administrador'),
            ),
          ),
        ],
      ),
    );
  }
}
