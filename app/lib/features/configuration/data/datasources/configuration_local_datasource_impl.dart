import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/features/configuration/data/datasources/configuration_local_datasource.dart';
import 'package:app/features/configuration/domain/entities/printer_configuration.dart';
import 'package:app/features/configuration/domain/entities/printer_connection_type.dart';
import 'package:app/features/configuration/domain/entities/receipt_settings.dart';

class ConfigurationLocalDataSourceImpl
    implements ConfigurationLocalDataSource {
  ConfigurationLocalDataSourceImpl(this._preferences);

  final SharedPreferences _preferences;

  static const _printerNameKey = 'configuration.printer.name';
  static const _printerTypeKey = 'configuration.printer.type';
  static const _receiptSettingsKey = 'configuration.receipt.settings';

  @override
  Future<PrinterConfiguration?> getPrinterConfiguration() async {
    final printerName = _preferences.getString(_printerNameKey);
    if (printerName == null || printerName.isEmpty) return null;

    final typeName = _preferences.getString(_printerTypeKey);
    return PrinterConfiguration(
      printerName: printerName,
      type: _typeFromName(typeName),
    );
  }

  @override
  Future<void> savePrinterConfiguration(
    PrinterConfiguration configuration,
  ) async {
    await _preferences.setString(_printerNameKey, configuration.printerName);
    await _preferences.setString(_printerTypeKey, configuration.type.name);
  }

  @override
  Future<void> clearPrinterConfiguration() async {
    await _preferences.remove(_printerNameKey);
    await _preferences.remove(_printerTypeKey);
  }

  @override
  Future<ReceiptSettings> getReceiptSettings() async {
    final raw = _preferences.getString(_receiptSettingsKey);
    if (raw == null || raw.isEmpty) return ReceiptSettings.defaults;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return ReceiptSettings.defaults;
    return ReceiptSettings.fromJson(decoded);
  }

  @override
  Future<void> saveReceiptSettings(ReceiptSettings settings) async {
    await _preferences.setString(
      _receiptSettingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  PrinterConnectionType _typeFromName(String? name) {
    return PrinterConnectionType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => PrinterConnectionType.usb,
    );
  }
}

