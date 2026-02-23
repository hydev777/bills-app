import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/products/domain/repositories/products_repository.dart';

class UpdateItemUseCase {
  UpdateItemUseCase(this._repository);

  final ProductsRepository _repository;

  Future<Result<ItemEntity, Failure>> call(
    int id, {
    String? name,
    String? description,
    double? unitPrice,
    int? categoryId,
    int? itbisRateId,
  }) =>
      _repository.updateItem(
        id,
        name: name,
        description: description,
        unitPrice: unitPrice,
        categoryId: categoryId,
        itbisRateId: itbisRateId,
      );
}
