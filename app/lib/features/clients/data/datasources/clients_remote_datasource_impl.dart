import 'package:dio/dio.dart';

import 'clients_remote_datasource.dart';

class ClientsRemoteDataSourceImpl implements ClientsRemoteDataSource {
  ClientsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getClients({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/clients',
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
  Future<Map<String, dynamic>> createClient({
    required String name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (identifier != null) 'identifier': identifier,
      if (taxId != null) 'tax_id': taxId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/clients',
      data: body,
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
  Future<Map<String, dynamic>> updateClient(
    int id, {
    String? name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (identifier != null) 'identifier': identifier,
      if (taxId != null) 'tax_id': taxId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    };

    final response = await _dio.put<Map<String, dynamic>>(
      '/api/clients/$id',
      data: body,
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
}
