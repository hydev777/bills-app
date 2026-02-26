import 'package:flutter/material.dart';

import 'package:app/features/clients/domain/entities/client_entity.dart';

class ClientFormBottomSheet extends StatefulWidget {
  const ClientFormBottomSheet({
    super.key,
    this.initialClient,
    this.onCreate,
    this.onUpdate,
    required this.onCancel,
  });

  final ClientEntity? initialClient;
  final void Function({
    required String name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  })? onCreate;
  final void Function({
    required int id,
    required String name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  })? onUpdate;
  final VoidCallback onCancel;

  @override
  State<ClientFormBottomSheet> createState() => _ClientFormBottomSheetState();
}

class _ClientFormBottomSheetState extends State<ClientFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final client = widget.initialClient;
    if (client != null) {
      _nameController.text = client.name;
      _identifierController.text = client.identifier ?? '';
      _taxIdController.text = client.taxId ?? '';
      _emailController.text = client.email ?? '';
      _phoneController.text = client.phone ?? '';
      _addressController.text = client.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim().isEmpty
        ? null
        : _identifierController.text.trim();
    final taxId = _taxIdController.text.trim().isEmpty
        ? null
        : _taxIdController.text.trim();
    final email = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();
    final phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();
    final address = _addressController.text.trim().isEmpty
        ? null
        : _addressController.text.trim();

    final client = widget.initialClient;
    if (client != null && widget.onUpdate != null) {
      widget.onUpdate!(
        id: client.id,
        name: name,
        identifier: identifier,
        taxId: taxId,
        email: email,
        phone: phone,
        address: address,
      );
    } else if (widget.onCreate != null) {
      widget.onCreate!(
        name: name,
        identifier: identifier,
        taxId: taxId,
        email: email,
        phone: phone,
        address: address,
      );
      _nameController.clear();
      _identifierController.clear();
      _taxIdController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
    } else {
      widget.onCancel();
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
                widget.initialClient != null ? 'Editar cliente' : 'Nuevo cliente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _ClientFormFields(
                nameController: _nameController,
                identifierController: _identifierController,
                taxIdController: _taxIdController,
                emailController: _emailController,
                phoneController: _phoneController,
                addressController: _addressController,
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
                    child: Text(
                      widget.initialClient != null ? 'Guardar' : 'Crear',
                    ),
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

class _ClientFormFields extends StatelessWidget {
  const _ClientFormFields({
    required this.nameController,
    required this.identifierController,
    required this.taxIdController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
  });

  final TextEditingController nameController;
  final TextEditingController identifierController;
  final TextEditingController taxIdController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es obligatorio';
            }
            if (value.trim().length > 100) {
              return 'Máximo 100 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: identifierController,
          decoration: const InputDecoration(
            labelText: 'Identificador (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: taxIdController,
          decoration: const InputDecoration(
            labelText: 'RNC/Cédula (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email (opcional)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono (opcional)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Dirección (opcional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

