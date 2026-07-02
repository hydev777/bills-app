import 'package:flutter/material.dart';

import 'package:app/features/configuration/domain/entities/receipt_settings.dart';
import 'package:app/features/configuration/domain/entities/receipt_snapshot.dart';

class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({
    super.key,
    required this.snapshot,
    required this.settings,
  });

  final ReceiptSnapshot snapshot;
  final ReceiptSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium ?? const TextStyle(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Facturacion',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Factura ${snapshot.publicId}', textAlign: TextAlign.center),
                Text(_formatDate(snapshot.createdAt), textAlign: TextAlign.center),
                const Divider(height: 24),
                if (settings.showProducts) ...[
                  ...snapshot.lines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            line.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  settings.showUnitPrices
                                      ? '${line.quantity} x ${_money(line.unitPrice)}'
                                      : 'Cantidad ${line.quantity}',
                                ),
                              ),
                              Text(_money(line.lineTotal)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 18),
                ],
                if (settings.showSubtotal)
                  _PreviewAmountRow(label: 'Subtotal', amount: snapshot.subtotal),
                if (settings.showTax)
                  _PreviewAmountRow(label: 'ITBIS', amount: snapshot.taxAmount),
                if (settings.showTotal)
                  _PreviewAmountRow(
                    label: 'Total a pagar',
                    amount: snapshot.totalAmount,
                    emphasis: true,
                  ),
                if (settings.showCashReceived)
                  _PreviewAmountRow(
                    label: 'Efectivo',
                    amount: snapshot.cashReceived,
                  ),
                if (settings.showChange)
                  _PreviewAmountRow(label: 'Cambio', amount: snapshot.change),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  String _money(double amount) => 'RD\$ ${amount.toStringAsFixed(2)}';
}

class _PreviewAmountRow extends StatelessWidget {
  const _PreviewAmountRow({
    required this.label,
    required this.amount,
    this.emphasis = false,
  });

  final String label;
  final double amount;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final style = emphasis
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('RD\$ ${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

