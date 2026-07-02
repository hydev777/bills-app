import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/domain/entities/printer_configuration.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';
import 'package:app/features/configuration/domain/entities/receipt_print_result.dart';

abstract class PrinterConfigurationRepository {
  Future<Result<List<PrinterDeviceEntity>, Failure>> discoverUsbPrinters();

  Future<Result<bool, Failure>> connect(PrinterDeviceEntity printer);

  Future<Result<void, Failure>> disconnect();

  Future<Result<PrinterConfiguration?, Failure>> getSavedPrinter();

  Future<Result<void, Failure>> savePrinter(PrinterConfiguration configuration);

  Future<Result<void, Failure>> clearPrinter();

  Future<Result<ReceiptPrintResult, Failure>> printBytes(List<int> bytes);
}

