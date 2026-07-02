import 'package:equatable/equatable.dart';

import 'printer_connection_type.dart';

class PrinterDeviceEntity extends Equatable {
  const PrinterDeviceEntity({
    required this.name,
    required this.type,
  });

  final String name;
  final PrinterConnectionType type;

  @override
  List<Object?> get props => [name, type];
}

