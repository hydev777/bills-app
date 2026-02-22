import 'package:app/core/constants/api_constants.dart';
import 'package:app/features/auth/data/models/login_response.dart';
import 'package:dio/dio.dart';

import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<LoginResponse> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.loginPath,
      data: {'email': email, 'password': password},
    );

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
