import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/products/domain/repositories/products_repository.dart';

class CreateItemUseCase {
  CreateItemUseCase(this._repository);

  final ProductsRepository _repository;

  Future<Result<ItemEntity, Failure>> call({
    required String name,
    String? description,
    required double unitPrice,
    int? categoryId,
    required int itbisRateId,
  }) =>
      _repository.createItem(
        name: name,
        description: description,
        unitPrice: unitPrice,
        categoryId: categoryId,
        itbisRateId: itbisRateId,
      );
}
