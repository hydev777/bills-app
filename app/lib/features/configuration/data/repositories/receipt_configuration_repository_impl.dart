import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/configuration/data/datasources/configuration_local_datasource.dart';
import 'package:app/features/configuration/domain/entities/receipt_settings.dart';
import 'package:app/features/configuration/domain/repositories/receipt_configuration_repository.dart';

class ReceiptConfigurationRepositoryImpl
    implements ReceiptConfigurationRepository {
  ReceiptConfigurationRepositoryImpl(this._localDataSource);

  final ConfigurationLocalDataSource _localDataSource;

  @override
  Future<Result<ReceiptSettings, Failure>> getSettings() async {
    try {
      return success(await _localDataSource.getReceiptSettings());
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> saveSettings(ReceiptSettings settings) async {
    try {
      await _localDataSource.saveReceiptSettings(settings);
      return success<void, Failure>(null);
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }
}
