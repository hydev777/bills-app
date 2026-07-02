import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/domain/entities/receipt_settings.dart';

abstract class ReceiptConfigurationRepository {
  Future<Result<ReceiptSettings, Failure>> getSettings();

  Future<Result<void, Failure>> saveSettings(ReceiptSettings settings);
}

