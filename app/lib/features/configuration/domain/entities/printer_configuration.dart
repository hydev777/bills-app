import 'package:equatable/equatable.dart';

import 'printer_connection_type.dart';

class PrinterConfiguration extends Equatable {
  const PrinterConfiguration({
    required this.printerName,
    required this.type,
  });

  final String printerName;
  final PrinterConnectionType type;

  @override
  List<Object?> get props => [printerName, type];
}

