import 'package:equatable/equatable.dart';

class ReceiptLine extends Equatable {
  const ReceiptLine({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  @override
  List<Object?> get props => [productName, quantity, unitPrice, lineTotal];
}

