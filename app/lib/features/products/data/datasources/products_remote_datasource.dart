import 'package:app/features/products/data/models/item_category_model.dart';
import 'package:app/features/products/data/models/item_model.dart';
import 'package:app/features/products/data/models/itbis_rate_model.dart';

abstract class ProductsRemoteDataSource {
  /// GET /api/items. Branch from X-Branch-Id header.
  Future<Map<String, dynamic>> getItems({
    String? category,
    String? search,
    int limit = 50,
    int offset = 0,
  });

  /// GET /api/items/categories
  Future<List<ItemCategoryModel>> getCategories();

  /// GET /api/itbis-rates
  Future<List<ItbisRateModel>> getItbisRates();

  /// POST /api/items. Body: name, description?, unit_price, category_id?, itbis_rate_id
  Future<ItemModel> createItem({
    required String name,
    String? description,
    required double unitPrice,
    int? categoryId,
    required int itbisRateId,
  });
}
