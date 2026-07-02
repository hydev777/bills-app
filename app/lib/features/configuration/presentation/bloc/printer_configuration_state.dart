import 'package:equatable/equatable.dart';

import 'package:app/features/configuration/domain/entities/printer_configuration.dart';
import 'package:app/features/configuration/domain/entities/printer_connection_status.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';

class PrinterConfigurationState extends Equatable {
  const PrinterConfigurationState({
    this.status = PrinterConnectionStatus.initial,
    this.printers = const <PrinterDeviceEntity>[],
    this.savedConfiguration,
    this.selectedPrinter,
    this.message,
  });

  final PrinterConnectionStatus status;
  final List<PrinterDeviceEntity> printers;
  final PrinterConfiguration? savedConfiguration;
  final PrinterDeviceEntity? selectedPrinter;
  final String? message;

  bool get isBusy => status == PrinterConnectionStatus.scanning;

  PrinterConfigurationState copyWith({
    PrinterConnectionStatus? status,
    List<PrinterDeviceEntity>? printers,
    PrinterConfiguration? savedConfiguration,
    PrinterDeviceEntity? selectedPrinter,
    String? message,
    bool clearSavedConfiguration = false,
    bool clearSelectedPrinter = false,
    bool clearMessage = false,
  }) {
    return PrinterConfigurationState(
      status: status ?? this.status,
      printers: printers ?? this.printers,
      savedConfiguration: clearSavedConfiguration
          ? null
          : (savedConfiguration ?? this.savedConfiguration),
      selectedPrinter: clearSelectedPrinter
          ? null
          : (selectedPrinter ?? this.selectedPrinter),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    status,
    printers,
    savedConfiguration,
    selectedPrinter,
    message,
  ];
}

