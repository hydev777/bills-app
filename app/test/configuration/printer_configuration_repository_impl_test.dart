import 'package:app/features/configuration/data/datasources/configuration_local_datasource.dart';
import 'package:app/features/configuration/data/datasources/printer_datasource.dart';
import 'package:app/features/configuration/data/repositories/printer_configuration_repository_impl.dart';
import 'package:app/features/configuration/domain/entities/printer_configuration.dart';
import 'package:app/features/configuration/domain/entities/printer_connection_type.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';
import 'package:app/features/configuration/domain/entities/receipt_print_result.dart';
import 'package:app/features/configuration/domain/entities/receipt_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrinterConfigurationRepositoryImpl.printBytes', () {
    test('returns notConfigured when no printer is saved', () async {
      final repository = PrinterConfigurationRepositoryImpl(
        localDataSource: _FakeConfigurationLocalDataSource(),
        printerDataSource: _FakePrinterDataSource(),
      );

      final result = await repository.printBytes(const [1, 2, 3]);

      expect(result.valueOrNull?.status, ReceiptPrintStatus.notConfigured);
    });

    test('returns disconnected when saved printer is missing', () async {
      final repository = PrinterConfigurationRepositoryImpl(
        localDataSource: _FakeConfigurationLocalDataSource(
          printerConfiguration: const PrinterConfiguration(
            printerName: 'Receipt Printer',
            type: PrinterConnectionType.usb,
          ),
        ),
        printerDataSource: _FakePrinterDataSource(),
      );

      final result = await repository.printBytes(const [1, 2, 3]);

      expect(result.valueOrNull?.status, ReceiptPrintStatus.disconnected);
    });

    test('prints bytes when saved printer is connected', () async {
      final printer = const PrinterDeviceEntity(
        name: 'Receipt Printer',
        type: PrinterConnectionType.usb,
      );
      final printerDataSource = _FakePrinterDataSource(
        printers: [printer],
        connectResult: true,
        sendResult: true,
      );
      final repository = PrinterConfigurationRepositoryImpl(
        localDataSource: _FakeConfigurationLocalDataSource(
          printerConfiguration: const PrinterConfiguration(
            printerName: 'Receipt Printer',
            type: PrinterConnectionType.usb,
          ),
        ),
        printerDataSource: printerDataSource,
      );

      final result = await repository.printBytes(const [1, 2, 3]);

      expect(result.valueOrNull?.status, ReceiptPrintStatus.printed);
      expect(printerDataSource.sentBytes, const [1, 2, 3]);
    });
  });
}

class _FakeConfigurationLocalDataSource implements ConfigurationLocalDataSource {
  _FakeConfigurationLocalDataSource({this.printerConfiguration});

  PrinterConfiguration? printerConfiguration;
  ReceiptSettings receiptSettings = ReceiptSettings.defaults;

  @override
  Future<void> clearPrinterConfiguration() async {
    printerConfiguration = null;
  }

  @override
  Future<PrinterConfiguration?> getPrinterConfiguration() async {
    return printerConfiguration;
  }

  @override
  Future<ReceiptSettings> getReceiptSettings() async {
    return receiptSettings;
  }

  @override
  Future<void> savePrinterConfiguration(
    PrinterConfiguration configuration,
  ) async {
    printerConfiguration = configuration;
  }

  @override
  Future<void> saveReceiptSettings(ReceiptSettings settings) async {
    receiptSettings = settings;
  }
}

class _FakePrinterDataSource implements PrinterDataSource {
  _FakePrinterDataSource({
    this.printers = const <PrinterDeviceEntity>[],
    this.connectResult = false,
    this.sendResult = false,
  });

  final List<PrinterDeviceEntity> printers;
  final bool connectResult;
  final bool sendResult;
  List<int>? sentBytes;

  @override
  Future<bool> connectUsbPrinter(PrinterDeviceEntity printer) async {
    return connectResult;
  }

  @override
  Future<bool> disconnectUsbPrinter() async {
    return true;
  }

  @override
  Future<List<PrinterDeviceEntity>> discoverUsbPrinters() async {
    return printers;
  }

  @override
  Future<bool> sendUsbBytes(List<int> bytes) async {
    sentBytes = bytes;
    return sendResult;
  }
}

