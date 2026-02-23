import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/products/domain/entities/item_category_entity.dart';
import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/products/domain/entities/itbis_rate_entity.dart';

abstract class ProductsRepository {
  /// Returns items list with total. Branch from session/header.
  Future<Result<ItemsListResult, Failure>> getItems({
    String? category,
    String? search,
    int limit = 50,
    int offset = 0,
  });

  Future<Result<List<ItemCategoryEntity>, Failure>> getCategories();

  Future<Result<List<ItbisRateEntity>, Failure>> getItbisRates();

  Future<Result<ItemEntity, Failure>> createItem({
    required String name,
    String? description,
    required double unitPrice,
    int? categoryId,
    required int itbisRateId,
  });

  Future<Result<ItemEntity, Failure>> updateItem(
    int id, {
    String? name,
    String? description,
    double? unitPrice,
    int? categoryId,
    int? itbisRateId,
  });
}

class ItemsListResult {
  const ItemsListResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<ItemEntity> items;
  final int total;
  final int limit;
  final int offset;
}
