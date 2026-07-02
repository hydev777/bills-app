import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/data/datasources/configuration_local_datasource.dart';
import 'package:app/features/configuration/data/datasources/printer_datasource.dart';
import 'package:app/features/configuration/domain/entities/printer_configuration.dart';
import 'package:app/features/configuration/domain/entities/printer_connection_type.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';
import 'package:app/features/configuration/domain/entities/receipt_print_result.dart';
import 'package:app/features/configuration/domain/repositories/printer_configuration_repository.dart';

class PrinterConfigurationRepositoryImpl
    implements PrinterConfigurationRepository {
  PrinterConfigurationRepositoryImpl({
    required ConfigurationLocalDataSource localDataSource,
    required PrinterDataSource printerDataSource,
  }) : _localDataSource = localDataSource,
       _printerDataSource = printerDataSource;

  final ConfigurationLocalDataSource _localDataSource;
  final PrinterDataSource _printerDataSource;

  @override
  Future<Result<List<PrinterDeviceEntity>, Failure>>
  discoverUsbPrinters() async {
    try {
      final printers = await _printerDataSource.discoverUsbPrinters();
      return success(printers);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<bool, Failure>> connect(PrinterDeviceEntity printer) async {
    try {
      final connected = await _printerDataSource.connectUsbPrinter(printer);
      return success(connected);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> disconnect() async {
    try {
      await _printerDataSource.disconnectUsbPrinter();
      return success<void, Failure>(null);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<PrinterConfiguration?, Failure>> getSavedPrinter() async {
    try {
      return success(await _localDataSource.getPrinterConfiguration());
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> savePrinter(
    PrinterConfiguration configuration,
  ) async {
    try {
      await _localDataSource.savePrinterConfiguration(configuration);
      return success<void, Failure>(null);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> clearPrinter() async {
    try {
      await _localDataSource.clearPrinterConfiguration();
      await _printerDataSource.disconnectUsbPrinter();
      return success<void, Failure>(null);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ReceiptPrintResult, Failure>> printBytes(
    List<int> bytes,
  ) async {
    try {
      final configuration = await _localDataSource.getPrinterConfiguration();
      if (configuration == null) {
        return success(
          const ReceiptPrintResult(
            status: ReceiptPrintStatus.notConfigured,
            message: 'No hay impresora configurada',
          ),
        );
      }

      final printers = await _printerDataSource.discoverUsbPrinters();
      final printer = _findSavedPrinter(printers, configuration);
      if (printer == null) {
        return success(
          const ReceiptPrintResult(
            status: ReceiptPrintStatus.disconnected,
            message: 'La impresora configurada no esta conectada',
          ),
        );
      }

      final connected = await _printerDataSource.connectUsbPrinter(printer);
      if (!connected) {
        return success(
          const ReceiptPrintResult(
            status: ReceiptPrintStatus.disconnected,
            message: 'No se pudo conectar con la impresora',
          ),
        );
      }

      final printed = await _printerDataSource.sendUsbBytes(bytes);
      if (!printed) {
        return success(
          const ReceiptPrintResult(
            status: ReceiptPrintStatus.failed,
            message: 'No se pudo imprimir el recibo',
          ),
        );
      }

      return success(
        const ReceiptPrintResult(status: ReceiptPrintStatus.printed),
      );
    } catch (e) {
      return success(
        ReceiptPrintResult(
          status: ReceiptPrintStatus.failed,
          message: e.toString(),
        ),
      );
    }
  }

  PrinterDeviceEntity? _findSavedPrinter(
    List<PrinterDeviceEntity> printers,
    PrinterConfiguration configuration,
  ) {
    if (configuration.type != PrinterConnectionType.usb) return null;
    for (final printer in printers) {
      if (printer.name == configuration.printerName) return printer;
    }
    return null;
  }
}
