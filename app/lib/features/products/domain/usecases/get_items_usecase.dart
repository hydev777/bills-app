import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/products/domain/repositories/products_repository.dart';

class GetItemsUseCase {
  GetItemsUseCase(this._repository);

  final ProductsRepository _repository;

  Future<Result<ItemsListResult, Failure>> call({
    String? category,
    String? search,
    int limit = 50,
    int offset = 0,
  }) =>
      _repository.getItems(
        category: category,
        search: search,
        limit: limit,
        offset: offset,
      );
}
