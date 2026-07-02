import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';

abstract class PrinterDataSource {
  Future<List<PrinterDeviceEntity>> discoverUsbPrinters();

  Future<bool> connectUsbPrinter(PrinterDeviceEntity printer);

  Future<bool> disconnectUsbPrinter();

  Future<bool> sendUsbBytes(List<int> bytes);
}

