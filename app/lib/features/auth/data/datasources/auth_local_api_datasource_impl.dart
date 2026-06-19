import 'package:app/core/constants/api_constants.dart';
import 'package:app/features/auth/data/models/login_response.dart';
import 'package:dio/dio.dart';

import 'auth_local_api_datasource.dart';

class AuthLocalApiDataSourceImpl implements AuthLocalApiDataSource {
  AuthLocalApiDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<LoginResponse> login(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.loginPath,
      data: {'username': username, 'password': password},
    );
    return _responseToLogin(response);
  }

  @override
  Future<bool> hasLocalUsers() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/users/bootstrap-status',
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return data['hasUsers'] as bool? ?? false;
  }

  @override
  Future<LoginResponse> createInitialAdmin({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/users/bootstrap-admin',
      data: {'username': username, 'password': password},
    );
    return _responseToLogin(response);
  }

  LoginResponse _responseToLogin(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return LoginResponse.fromJson(data);
  }
}
