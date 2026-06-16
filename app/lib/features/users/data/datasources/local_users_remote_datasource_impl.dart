import 'package:app/features/users/data/datasources/local_users_remote_datasource.dart';
import 'package:app/features/users/data/models/local_user_model.dart';
import 'package:dio/dio.dart';

class LocalUsersRemoteDataSourceImpl implements LocalUsersRemoteDataSource {
  LocalUsersRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<LocalUserModel>> getUsers() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/users');
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    final list = data['users'] as List<dynamic>? ?? [];
    return list
        .map((e) => LocalUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LocalUserModel> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/users',
      data: {'username': username, 'password': password, 'role': role},
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return LocalUserModel.fromJson(data);
  }

  @override
  Future<LocalUserModel> updateUser({
    required int id,
    required String username,
    String? password,
    required String role,
  }) async {
    final body = <String, dynamic>{'username': username, 'role': role};
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/users/$id',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return LocalUserModel.fromJson(data);
  }

  @override
  Future<void> deleteUser(int id) async {
    await _dio.delete<void>('/api/users/$id');
  }
}
