import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/configuration/domain/entities/printer_configuration.dart';
import 'package:app/features/configuration/domain/entities/printer_connection_status.dart';
import 'package:app/features/configuration/domain/entities/printer_connection_type.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';
import 'package:app/features/configuration/domain/usecases/check_printer_connection_usecase.dart';
import 'package:app/features/configuration/domain/usecases/clear_printer_configuration_usecase.dart';
import 'package:app/features/configuration/domain/usecases/disconnect_printer_usecase.dart';
import 'package:app/features/configuration/domain/usecases/discover_printers_usecase.dart';
import 'package:app/features/configuration/domain/usecases/get_printer_configuration_usecase.dart';
import 'package:app/features/configuration/domain/usecases/save_printer_configuration_usecase.dart';

import 'printer_configuration_state.dart';

class PrinterConfigurationCubit extends Cubit<PrinterConfigurationState> {
  PrinterConfigurationCubit({
    required GetPrinterConfigurationUseCase getPrinterConfigurationUseCase,
    required DiscoverPrintersUseCase discoverPrintersUseCase,
    required SavePrinterConfigurationUseCase savePrinterConfigurationUseCase,
    required CheckPrinterConnectionUseCase checkPrinterConnectionUseCase,
    required DisconnectPrinterUseCase disconnectPrinterUseCase,
    required ClearPrinterConfigurationUseCase clearPrinterConfigurationUseCase,
  }) : _getPrinterConfigurationUseCase = getPrinterConfigurationUseCase,
       _discoverPrintersUseCase = discoverPrintersUseCase,
       _savePrinterConfigurationUseCase = savePrinterConfigurationUseCase,
       _checkPrinterConnectionUseCase = checkPrinterConnectionUseCase,
       _disconnectPrinterUseCase = disconnectPrinterUseCase,
       _clearPrinterConfigurationUseCase = clearPrinterConfigurationUseCase,
       super(const PrinterConfigurationState());

  final GetPrinterConfigurationUseCase _getPrinterConfigurationUseCase;
  final DiscoverPrintersUseCase _discoverPrintersUseCase;
  final SavePrinterConfigurationUseCase _savePrinterConfigurationUseCase;
  final CheckPrinterConnectionUseCase _checkPrinterConnectionUseCase;
  final DisconnectPrinterUseCase _disconnectPrinterUseCase;
  final ClearPrinterConfigurationUseCase _clearPrinterConfigurationUseCase;

  Timer? _pollingTimer;
  bool _isRefreshing = false;

  Future<void> load() async {
    final result = await _getPrinterConfigurationUseCase();
    final configuration = result.valueOrNull;
    emit(state.copyWith(savedConfiguration: configuration));
    await refresh();
    _startPolling();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      if (isClosed) return;
      emit(state.copyWith(status: PrinterConnectionStatus.scanning));

      final result = await _discoverPrintersUseCase();
      final failure = result.errorOrNull;
      final printers = result.valueOrNull;
      if (failure != null || printers == null) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: PrinterConnectionStatus.error,
            message: failure?.displayMessage ?? 'No se pudo buscar impresoras',
          ),
        );
        return;
      }

      final saved = state.savedConfiguration;
      final selected = _selectPrinter(printers, saved, state.selectedPrinter);
      final status = await _statusFor(printers, saved, selected);

      if (isClosed) return;
      emit(
        state.copyWith(
          status: status,
          printers: printers,
          selectedPrinter: selected,
          clearSelectedPrinter: selected == null,
        ),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  void selectPrinter(PrinterDeviceEntity printer) {
    final nextStatus = state.savedConfiguration?.printerName == printer.name
        ? state.status
        : PrinterConnectionStatus.detected;
    emit(
      state.copyWith(
        selectedPrinter: printer,
        status: nextStatus,
        clearMessage: true,
      ),
    );
  }

  Future<void> saveSelectedPrinter() async {
    final selected = state.selectedPrinter;
    if (selected == null) return;

    final configuration = PrinterConfiguration(
      printerName: selected.name,
      type: PrinterConnectionType.usb,
    );
    final result = await _savePrinterConfigurationUseCase(configuration);
    final failure = result.errorOrNull;
    if (failure != null) {
      emit(
        state.copyWith(
          status: PrinterConnectionStatus.error,
          message: failure.displayMessage,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        savedConfiguration: configuration,
        clearMessage: true,
      ),
    );
    await refresh();
    emit(state.copyWith(message: 'Impresora guardada'));
  }

  Future<void> disconnect() async {
    await _disconnectPrinterUseCase();
    emit(state.copyWith(status: PrinterConnectionStatus.disconnected));
  }

  Future<void> clearConfiguration() async {
    await _clearPrinterConfigurationUseCase();
    emit(
      state.copyWith(
        status: state.printers.isEmpty
            ? PrinterConnectionStatus.notDetected
            : PrinterConnectionStatus.detected,
        clearSavedConfiguration: true,
        clearSelectedPrinter: true,
        message: 'Configuracion eliminada',
      ),
    );
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refresh(),
    );
  }

  PrinterDeviceEntity? _selectPrinter(
    List<PrinterDeviceEntity> printers,
    PrinterConfiguration? saved,
    PrinterDeviceEntity? selected,
  ) {
    if (saved != null) {
      for (final printer in printers) {
        if (printer.name == saved.printerName) return printer;
      }
      if (selected != null && selected.name != saved.printerName) {
        for (final printer in printers) {
          if (printer.name == selected.name) return printer;
        }
      }
      return null;
    }
    if (selected != null) {
      for (final printer in printers) {
        if (printer.name == selected.name) return printer;
      }
    }
    return printers.isEmpty ? null : printers.first;
  }

  Future<PrinterConnectionStatus> _statusFor(
    List<PrinterDeviceEntity> printers,
    PrinterConfiguration? saved,
    PrinterDeviceEntity? selected,
  ) async {
    if (printers.isEmpty) {
      return saved == null
          ? PrinterConnectionStatus.notDetected
          : PrinterConnectionStatus.disconnected;
    }
    if (saved != null && selected == null) {
      return PrinterConnectionStatus.disconnected;
    }
    if (saved == null || selected == null) {
      return PrinterConnectionStatus.detected;
    }
    if (saved.printerName != selected.name) {
      return PrinterConnectionStatus.detected;
    }

    final connectedResult = await _checkPrinterConnectionUseCase(selected);
    final connected = connectedResult.valueOrNull ?? false;
    return connected
        ? PrinterConnectionStatus.connected
        : PrinterConnectionStatus.disconnected;
  }
}
