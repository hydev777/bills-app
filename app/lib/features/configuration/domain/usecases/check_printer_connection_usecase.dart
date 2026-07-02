import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';
import 'package:app/features/configuration/domain/repositories/printer_configuration_repository.dart';

class CheckPrinterConnectionUseCase {
  CheckPrinterConnectionUseCase(this._repository);

  final PrinterConfigurationRepository _repository;

  Future<Result<bool, Failure>> call(PrinterDeviceEntity printer) {
    return _repository.connect(printer);
  }
}

