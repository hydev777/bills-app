import 'package:dio/dio.dart';

import 'bills_remote_datasource.dart';
import 'package:app/features/bills/data/models/bill_model.dart';

class BillsRemoteDataSourceImpl implements BillsRemoteDataSource {
  BillsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getBills({
    String? status,
    int? userId,
    int? clientId,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (userId != null) {
      queryParams['user_id'] = userId;
    }
    if (clientId != null) {
      queryParams['client_id'] = clientId;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/bills',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return data;
  }

  @override
  Future<BillModel> getBillById(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/bills/$id');
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return BillModel.fromJson(data);
  }

  @override
  Future<BillModel> getBillByPublicId(String publicId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/bills/public/$publicId');
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return BillModel.fromJson(data);
  }

  @override
  Future<BillModel> createBill({
    required String title,
    String? description,
    double? amount,
    String status = 'paid',
    int? clientId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'status': status,
    };
    if (description != null) {
      body['description'] = description;
    }
    if (amount != null) {
      body['amount'] = amount;
    }
    if (clientId != null) {
      body['client_id'] = clientId;
    }

    final response =
        await _dio.post<Map<String, dynamic>>('/api/bills', data: body);
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return BillModel.fromJson(data);
  }

  @override
  Future<void> createBillItems({
    required int billId,
    required List<({int itemId, int quantity, double unitPrice})> lines,
  }) async {
    for (final line in lines) {
      await _dio.post<Map<String, dynamic>>(
        '/api/bill-items',
        data: <String, dynamic>{
          'bill_id': billId,
          'item_id': line.itemId,
          'quantity': line.quantity,
          'unit_price': line.unitPrice,
        },
      );
    }
  }
}

