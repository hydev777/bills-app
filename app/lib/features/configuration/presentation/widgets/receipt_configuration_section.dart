import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/configuration/domain/entities/receipt_line.dart';
import 'package:app/features/configuration/domain/entities/receipt_settings.dart';
import 'package:app/features/configuration/domain/entities/receipt_snapshot.dart';
import 'package:app/features/configuration/presentation/bloc/receipt_configuration_cubit.dart';
import 'package:app/features/configuration/presentation/bloc/receipt_configuration_state.dart';
import 'package:app/features/configuration/presentation/widgets/receipt_preview.dart';

class ReceiptConfigurationSection extends StatelessWidget {
  const ReceiptConfigurationSection({super.key});

  static final ReceiptSnapshot _sampleSnapshot = ReceiptSnapshot(
    billId: 1,
    publicId: 'F-000001',
    createdAt: DateTime(2026, 7, 1, 10, 30),
    lines: const [
      ReceiptLine(
        productName: 'Cafe molido',
        quantity: 2,
        unitPrice: 175,
        lineTotal: 350,
      ),
      ReceiptLine(
        productName: 'Filtro de papel',
        quantity: 1,
        unitPrice: 120,
        lineTotal: 120,
      ),
    ],
    subtotal: 470,
    taxAmount: 84.60,
    totalAmount: 554.60,
    cashReceived: 600,
    change: 45.40,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptConfigurationCubit, ReceiptConfigurationState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        if (state.status == ReceiptConfigurationStatus.loading ||
            state.status == ReceiptConfigurationStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == ReceiptConfigurationStatus.error) {
          return Center(
            child: Text(state.message ?? 'No se pudo cargar el recibo'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 840;
            if (compact) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _ReceiptTogglePanel(settings: state.settings),
                  const SizedBox(height: 16),
                  ReceiptPreview(
                    snapshot: _sampleSnapshot,
                    settings: state.settings,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 380,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _ReceiptTogglePanel(settings: state.settings),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      ReceiptPreview(
                        snapshot: _sampleSnapshot,
                        settings: state.settings,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ReceiptTogglePanel extends StatelessWidget {
  const _ReceiptTogglePanel({required this.settings});

  final ReceiptSettings settings;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReceiptConfigurationCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Contenido del recibo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _ReceiptSwitchTile(
          title: 'Productos',
          value: settings.showProducts,
          onChanged: (value) =>
              cubit.updateSettings(settings.copyWith(showProducts: value)),
        ),
        _ReceiptSwitchTile(
          title: 'Precios unitarios',
          value: settings.showUnitPrices,
          onChanged: settings.showProducts
              ? (value) => cubit.updateSettings(
                    settings.copyWith(showUnitPrices: value),
                  )
              : null,
        ),
        _ReceiptSwitchTile(
          title: 'Subtotal',
          value: settings.showSubtotal,
          onChanged: (value) =>
              cubit.updateSettings(settings.copyWith(showSubtotal: value)),
        ),
        _ReceiptSwitchTile(
          title: 'ITBIS',
          value: settings.showTax,
          onChanged: (value) =>
              cubit.updateSettings(settings.copyWith(showTax: value)),
        ),
        _ReceiptSwitchTile(
          title: 'Total a pagar',
          value: settings.showTotal,
          onChanged: (value) =>
              cubit.updateSettings(settings.copyWith(showTotal: value)),
        ),
        _ReceiptSwitchTile(
          title: 'Efectivo recibido',
          value: settings.showCashReceived,
          onChanged: (value) => cubit.updateSettings(
            settings.copyWith(showCashReceived: value),
          ),
        ),
        _ReceiptSwitchTile(
          title: 'Cambio',
          value: settings.showChange,
          onChanged: (value) =>
              cubit.updateSettings(settings.copyWith(showChange: value)),
        ),
      ],
    );
  }
}

class _ReceiptSwitchTile extends StatelessWidget {
  const _ReceiptSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

