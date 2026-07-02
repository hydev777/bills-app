import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/domain/entities/receipt_settings.dart';
import 'package:app/features/configuration/domain/repositories/receipt_configuration_repository.dart';

class SaveReceiptSettingsUseCase {
  SaveReceiptSettingsUseCase(this._repository);

  final ReceiptConfigurationRepository _repository;

  Future<Result<void, Failure>> call(ReceiptSettings settings) {
    return _repository.saveSettings(settings);
  }
}

