import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';

import 'package:app/features/configuration/domain/entities/receipt_settings.dart';
import 'package:app/features/configuration/domain/entities/receipt_snapshot.dart';

class ReceiptGenerator {
  Future<List<int>> generate({
    required ReceiptSnapshot snapshot,
    required ReceiptSettings settings,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(
      generator.text(
        'Facturacion',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(generator.text('Factura ${snapshot.publicId}'));
    bytes.addAll(generator.text(_formatDate(snapshot.createdAt)));
    bytes.addAll(generator.hr());

    if (settings.showProducts) {
      for (final line in snapshot.lines) {
        bytes.addAll(generator.text(line.productName));
        final left = settings.showUnitPrices
            ? '${line.quantity} x ${_money(line.unitPrice)}'
            : 'Cantidad ${line.quantity}';
        bytes.addAll(
          generator.row([
            PosColumn(text: left, width: 7),
            PosColumn(
              text: _money(line.lineTotal),
              width: 5,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]),
        );
      }
      bytes.addAll(generator.hr());
    }

    if (settings.showSubtotal) {
      bytes.addAll(_amountRow(generator, 'Subtotal', snapshot.subtotal));
    }
    if (settings.showTax) {
      bytes.addAll(_amountRow(generator, 'ITBIS', snapshot.taxAmount));
    }
    if (settings.showTotal) {
      bytes.addAll(
        _amountRow(
          generator,
          'Total a pagar',
          snapshot.totalAmount,
          bold: true,
        ),
      );
    }
    if (settings.showCashReceived) {
      bytes.addAll(_amountRow(generator, 'Efectivo', snapshot.cashReceived));
    }
    if (settings.showChange) {
      bytes.addAll(_amountRow(generator, 'Cambio', snapshot.change));
    }

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    return bytes;
  }

  List<int> _amountRow(
    Generator generator,
    String label,
    double amount, {
    bool bold = false,
  }) {
    return generator.row([
      PosColumn(
        text: label,
        width: 7,
        styles: PosStyles(bold: bold),
      ),
      PosColumn(
        text: _money(amount),
        width: 5,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _money(double amount) => 'RD\$ ${amount.toStringAsFixed(2)}';
}
