import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/products/domain/entities/item_category_entity.dart';
import 'package:app/features/products/domain/repositories/products_repository.dart';

class GetCategoriesUseCase {
  GetCategoriesUseCase(this._repository);

  final ProductsRepository _repository;

  Future<Result<List<ItemCategoryEntity>, Failure>> call() =>
      _repository.getCategories();
}
