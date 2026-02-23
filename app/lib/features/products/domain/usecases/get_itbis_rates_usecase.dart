import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/products/domain/entities/itbis_rate_entity.dart';
import 'package:app/features/products/domain/repositories/products_repository.dart';

class GetItbisRatesUseCase {
  GetItbisRatesUseCase(this._repository);

  final ProductsRepository _repository;

  Future<Result<List<ItbisRateEntity>, Failure>> call() =>
      _repository.getItbisRates();
}
