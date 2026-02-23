import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/products/domain/entities/item_category_entity.dart';
import 'package:app/features/products/domain/entities/item_entity.dart';
import 'package:app/features/products/domain/entities/itbis_rate_entity.dart';
import 'package:app/features/products/domain/repositories/products_repository.dart';
import 'package:app/features/products/data/datasources/products_remote_datasource.dart';
import 'package:dio/dio.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl(this._remote);

  final ProductsRemoteDataSource _remote;

  @override
  Future<Result<ItemsListResult, Failure>> getItems({
    String? category,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await _remote.getItems(
        category: category,
        search: search,
        limit: limit,
        offset: offset,
      );
      final itemsList = data['items'] as List<dynamic>? ?? [];
      final items = itemsList
          .map((e) => (e as Map<String, dynamic>))
          .map((e) => _itemFromJson(e))
          .toList();
      final total = data['total'] as int? ?? 0;
      final limitVal = data['limit'] as int? ?? limit;
      final offsetVal = data['offset'] as int? ?? offset;
      return success(ItemsListResult(
        items: items,
        total: total,
        limit: limitVal,
        offset: offsetVal,
      ));
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDio(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  ItemEntity _itemFromJson(Map<String, dynamic> json) {
    final itbisRate = json['itbisRate'] as Map<String, dynamic>?;
    return ItemEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      unitPrice: _toDouble(json['unitPrice']),
      categoryId: json['categoryId'] as int?,
      itbisRateId: json['itbisRateId'] as int,
      itbisRateName: itbisRate?['name'] as String?,
      itbisPercentage: itbisRate != null ? _toDouble(itbisRate['percentage']) : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Future<Result<List<ItemCategoryEntity>, Failure>> getCategories() async {
    try {
      final list = await _remote.getCategories();
      return success(list.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDio(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ItbisRateEntity>, Failure>> getItbisRates() async {
    try {
      final list = await _remote.getItbisRates();
      return success(list.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDio(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ItemEntity, Failure>> createItem({
    required String name,
    String? description,
    required double unitPrice,
    int? categoryId,
    required int itbisRateId,
  }) async {
    try {
      final item = await _remote.createItem(
        name: name,
        description: description,
        unitPrice: unitPrice,
        categoryId: categoryId,
        itbisRateId: itbisRateId,
      );
      return success(item.toEntity());
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data as Map)['error']?.toString() ?? _messageFromDio(e)
          : _messageFromDio(e);
      return failure(ServerFailure(message: msg));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ItemEntity, Failure>> updateItem(
    int id, {
    String? name,
    String? description,
    double? unitPrice,
    int? categoryId,
    int? itbisRateId,
  }) async {
    try {
      final item = await _remote.updateItem(
        id,
        name: name,
        description: description,
        unitPrice: unitPrice,
        categoryId: categoryId,
        itbisRateId: itbisRateId,
      );
      return success(item.toEntity());
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data as Map)['error']?.toString() ?? _messageFromDio(e)
          : _messageFromDio(e);
      return failure(ServerFailure(message: msg));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  String _messageFromDio(DioException e) {
    final m = e.message;
    if (m != null && m.isNotEmpty) return m;
    final code = e.response?.statusCode;
    if (code != null) return 'Error del servidor: $code';
    return 'Error de conexión';
  }
}
