import 'dart:io';

import 'package:thermal_printer/thermal_printer.dart';

import 'package:app/features/configuration/data/datasources/printer_datasource.dart';
import 'package:app/features/configuration/domain/entities/printer_connection_type.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';

class ThermalPrinterDataSourceImpl implements PrinterDataSource {
  ThermalPrinterDataSourceImpl(this._printerManager);

  final PrinterManager _printerManager;

  @override
  Future<List<PrinterDeviceEntity>> discoverUsbPrinters() async {
    if (!Platform.isWindows) return const <PrinterDeviceEntity>[];

    final devices = <PrinterDeviceEntity>[];
    await for (final device in _printerManager.discovery(
      type: PrinterType.usb,
    )) {
      if (device.name.trim().isEmpty) continue;
      devices.add(
        PrinterDeviceEntity(
          name: device.name,
          type: PrinterConnectionType.usb,
        ),
      );
    }
    return devices;
  }

  @override
  Future<bool> connectUsbPrinter(PrinterDeviceEntity printer) {
    return _printerManager.connect(
      type: PrinterType.usb,
      model: UsbPrinterInput(name: printer.name),
    );
  }

  @override
  Future<bool> disconnectUsbPrinter() {
    return _printerManager.disconnect(type: PrinterType.usb);
  }

  @override
  Future<bool> sendUsbBytes(List<int> bytes) {
    return _printerManager.send(type: PrinterType.usb, bytes: bytes);
  }
}

