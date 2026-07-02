import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/domain/repositories/printer_configuration_repository.dart';

class ClearPrinterConfigurationUseCase {
  ClearPrinterConfigurationUseCase(this._repository);

  final PrinterConfigurationRepository _repository;

  Future<Result<void, Failure>> call() => _repository.clearPrinter();
}

