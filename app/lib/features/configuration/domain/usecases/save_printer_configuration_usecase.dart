import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/domain/entities/printer_configuration.dart';
import 'package:app/features/configuration/domain/repositories/printer_configuration_repository.dart';

class SavePrinterConfigurationUseCase {
  SavePrinterConfigurationUseCase(this._repository);

  final PrinterConfigurationRepository _repository;

  Future<Result<void, Failure>> call(PrinterConfiguration configuration) {
    return _repository.savePrinter(configuration);
  }
}

