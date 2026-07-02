import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';
import 'package:app/features/configuration/domain/repositories/printer_configuration_repository.dart';

class DiscoverPrintersUseCase {
  DiscoverPrintersUseCase(this._repository);

  final PrinterConfigurationRepository _repository;

  Future<Result<List<PrinterDeviceEntity>, Failure>> call() {
    return _repository.discoverUsbPrinters();
  }
}

