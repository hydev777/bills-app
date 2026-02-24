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
}
