import 'package:dio/dio.dart';

import 'package:app/features/products/data/models/item_category_model.dart';
import 'package:app/features/products/data/models/item_model.dart';
import 'package:app/features/products/data/models/itbis_rate_model.dart';

import 'products_remote_datasource.dart';

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  ProductsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getItems({
    String? category,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/items',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null) throw DioException(requestOptions: response.requestOptions, message: 'Empty response');
    return data;
  }

  @override
  Future<List<ItemCategoryModel>> getCategories() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/items/categories');
    final data = response.data;
    if (data == null) throw DioException(requestOptions: response.requestOptions, message: 'Empty response');
    final list = data['categories'] as List<dynamic>? ?? [];
    return list.map((e) => ItemCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ItbisRateModel>> getItbisRates() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/itbis-rates');
    final data = response.data;
    if (data == null) throw DioException(requestOptions: response.requestOptions, message: 'Empty response');
    final list = data['itbis_rates'] as List<dynamic>? ?? [];
    return list.map((e) => ItbisRateModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ItemModel> createItem({
    required String name,
    String? description,
    required double unitPrice,
    int? categoryId,
    required int itbisRateId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'unit_price': unitPrice,
      'itbis_rate_id': itbisRateId,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (categoryId != null) body['category_id'] = categoryId;

    final response = await _dio.post<Map<String, dynamic>>('/api/items', data: body);
    final data = response.data;
    if (data == null) throw DioException(requestOptions: response.requestOptions, message: 'Empty response');
    return ItemModel.fromJson(data);
  }
}
