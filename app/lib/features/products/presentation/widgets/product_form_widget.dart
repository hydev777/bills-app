import 'package:flutter/material.dart';

import 'package:app/features/products/domain/entities/item_category_entity.dart';
import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/products/domain/entities/itbis_rate_entity.dart';

class ProductFormWidget extends StatefulWidget {
  const ProductFormWidget({
    super.key,
    required this.categories,
    required this.itbisRates,
    required this.onCancel,
    this.initialItem,
    this.onCreate,
    this.onUpdate,
  });

  final List<ItemCategoryEntity> categories;
  final List<ItbisRateEntity> itbisRates;
  final ItemEntity? initialItem;
  final void Function({
    required String name,
    String? description,
    required double unitPrice,
    int? categoryId,
    required int itbisRateId,
  })? onCreate;
  final void Function({
    required int id,
    required String name,
    String? description,
    required double unitPrice,
    int? categoryId,
    required int itbisRateId,
  })? onUpdate;
  final VoidCallback onCancel;

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  ItemCategoryEntity? _selectedCategory;
  ItbisRateEntity? _selectedItbis;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _priceController.text = item.unitPrice.toStringAsFixed(2);
      for (final c in widget.categories) {
        if (c.id == item.categoryId) {
          _selectedCategory = c;
          break;
        }
      }
      for (final r in widget.itbisRates) {
        if (r.id == item.itbisRateId) {
          _selectedItbis = r;
          break;
        }
      }
      if (_selectedItbis == null && widget.itbisRates.isNotEmpty) {
        _selectedItbis = widget.itbisRates.first;
      }
    } else if (widget.itbisRates.length == 1) {
      _selectedItbis = widget.itbisRates.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItbis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una tasa ITBIS')),
      );
      return;
    }
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precio debe ser mayor que 0')),
      );
      return;
    }
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final categoryId = _selectedCategory?.id;
    final itbisRateId = _selectedItbis!.id;

    final item = widget.initialItem;
    if (item != null && widget.onUpdate != null) {
      widget.onUpdate!(
        id: item.id,
        name: name,
        description: description,
        unitPrice: price,
        categoryId: categoryId,
        itbisRateId: itbisRateId,
      );
    } else if (widget.onCreate != null) {
      widget.onCreate!(name: name, description: description, unitPrice: price, categoryId: categoryId, itbisRateId: itbisRateId);
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
                widget.initialItem != null ? 'Editar producto' : 'Nuevo producto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Requerido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Requerido';
                  final number = double.tryParse(value.trim());
                  if (number == null || number <= 0) return 'Debe ser mayor que 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ItemCategoryEntity?>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría (opcional)',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Sin categoría'),
                items: [
                  const DropdownMenuItem<ItemCategoryEntity?>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  ...widget.categories.map(
                    (c) => DropdownMenuItem<ItemCategoryEntity?>(
                      value: c,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (selectedCategory) => setState(() => _selectedCategory = selectedCategory),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ItbisRateEntity?>(
                value: _selectedItbis,
                decoration: const InputDecoration(
                  labelText: 'Tasa ITBIS',
                  border: OutlineInputBorder(),
                ),
                items: widget.itbisRates
                    .map(
                      (r) => DropdownMenuItem<ItbisRateEntity?>(
                        value: r,
                        child: Text('${r.name} (${r.percentage}%)'),
                      ),
                    )
                    .toList(),
                onChanged: (selectedRate) => setState(() => _selectedItbis = selectedRate),
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
                    child: Text(widget.initialItem != null ? 'Guardar' : 'Crear'),
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
