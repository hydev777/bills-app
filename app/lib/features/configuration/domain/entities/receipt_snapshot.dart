import 'package:equatable/equatable.dart';

import 'receipt_line.dart';

class ReceiptSnapshot extends Equatable {
  const ReceiptSnapshot({
    required this.billId,
    required this.publicId,
    required this.createdAt,
    required this.lines,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.cashReceived,
    required this.change,
  });

  final int billId;
  final String publicId;
  final DateTime createdAt;
  final List<ReceiptLine> lines;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double cashReceived;
  final double change;

  @override
  List<Object?> get props => [
    billId,
    publicId,
    createdAt,
    lines,
    subtotal,
    taxAmount,
    totalAmount,
    cashReceived,
    change,
  ];
}

