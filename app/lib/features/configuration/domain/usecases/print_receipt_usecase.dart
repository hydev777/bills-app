import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/domain/entities/receipt_print_result.dart';
import 'package:app/features/configuration/domain/entities/receipt_snapshot.dart';
import 'package:app/features/configuration/domain/repositories/printer_configuration_repository.dart';
import 'package:app/features/configuration/domain/repositories/receipt_configuration_repository.dart';
import 'package:app/features/configuration/domain/services/receipt_generator.dart';

class PrintReceiptUseCase {
  PrintReceiptUseCase({
    required PrinterConfigurationRepository printerRepository,
    required ReceiptConfigurationRepository receiptRepository,
    required ReceiptGenerator receiptGenerator,
  }) : _printerRepository = printerRepository,
       _receiptRepository = receiptRepository,
       _receiptGenerator = receiptGenerator;

  final PrinterConfigurationRepository _printerRepository;
  final ReceiptConfigurationRepository _receiptRepository;
  final ReceiptGenerator _receiptGenerator;

  Future<Result<ReceiptPrintResult, Failure>> call(
    ReceiptSnapshot snapshot,
  ) async {
    final settingsResult = await _receiptRepository.getSettings();
    final settingsFailure = settingsResult.errorOrNull;
    final settings = settingsResult.valueOrNull;
    if (settingsFailure != null || settings == null) {
      return failure(
        settingsFailure ??
            const ServerFailure(message: 'No se pudo leer el recibo'),
      );
    }

    final bytes = await _receiptGenerator.generate(
      snapshot: snapshot,
      settings: settings,
    );
    return _printerRepository.printBytes(bytes);
  }
}

