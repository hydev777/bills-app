import 'package:flutter/material.dart';

import 'package:app/features/users/domain/entities/local_user_entity.dart';

class UserFormBottomSheet extends StatefulWidget {
  const UserFormBottomSheet({
    super.key,
    this.initialUser,
    this.onCreate,
    this.onUpdate,
    required this.onCancel,
  });

  final LocalUserEntity? initialUser;
  final void Function({
    required String username,
    required String password,
    required String role,
  })?
  onCreate;
  final void Function({
    required int id,
    required String username,
    String? password,
    required String role,
  })?
  onUpdate;
  final VoidCallback onCancel;

  @override
  State<UserFormBottomSheet> createState() => _UserFormBottomSheetState();
}

class _UserFormBottomSheetState extends State<UserFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _role = 'user';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isEditing => widget.initialUser != null;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    if (user != null) {
      _usernameController.text = user.username;
      _role = user.role;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final password = _passwordController.text;
    if (_isEditing && widget.onUpdate != null) {
      widget.onUpdate!(
        id: widget.initialUser!.id,
        username: _usernameController.text.trim(),
        password: password.isEmpty ? null : password,
        role: _role,
      );
      return;
    }
    if (widget.onCreate != null) {
      widget.onCreate!(
        username: _usernameController.text.trim(),
        password: password,
        role: _role,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Editar usuario' : 'Nuevo usuario',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'El usuario es obligatorio';
                  if (text.length < 3) return 'Minimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'administrador',
                    child: Text('Administrador'),
                  ),
                  DropdownMenuItem(value: 'cajero', child: Text('Cajero')),
                  DropdownMenuItem(value: 'user', child: Text('Usuario')),
                ],
                onChanged: (value) => setState(() => _role = value ?? 'user'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Contrasena (opcional)'
                      : 'Contrasena',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  final text = value ?? '';
                  if (!_isEditing && text.isEmpty) {
                    return 'La contrasena es obligatoria';
                  }
                  if (text.isNotEmpty && text.length < 8) {
                    return 'Minimo 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Confirmar contrasena (opcional)'
                      : 'Confirmar contrasena',
                  border: const OutlineInputBorder(),
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
                  final password = _passwordController.text;
                  final confirm = value ?? '';
                  if (!_isEditing && confirm.isEmpty) {
                    return 'Confirme la contrasena';
                  }
                  if (password.isNotEmpty && confirm != password) {
                    return 'Las contrasenas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(_isEditing ? 'Guardar' : 'Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
