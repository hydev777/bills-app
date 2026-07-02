import 'package:equatable/equatable.dart';

enum ReceiptPrintStatus { printed, notConfigured, disconnected, failed }

class ReceiptPrintResult extends Equatable {
  const ReceiptPrintResult({
    required this.status,
    this.message,
  });

  final ReceiptPrintStatus status;
  final String? message;

  bool get isPrinted => status == ReceiptPrintStatus.printed;

  @override
  List<Object?> get props => [status, message];
}

