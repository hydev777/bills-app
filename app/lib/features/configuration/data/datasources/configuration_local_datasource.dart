import 'package:app/features/configuration/domain/entities/printer_configuration.dart';
import 'package:app/features/configuration/domain/entities/receipt_settings.dart';

abstract class ConfigurationLocalDataSource {
  Future<PrinterConfiguration?> getPrinterConfiguration();

  Future<void> savePrinterConfiguration(PrinterConfiguration configuration);

  Future<void> clearPrinterConfiguration();

  Future<ReceiptSettings> getReceiptSettings();

  Future<void> saveReceiptSettings(ReceiptSettings settings);
}

