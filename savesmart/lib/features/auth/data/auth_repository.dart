import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/errors/bank_error.dart';
import '../domain/session.dart';

class AuthRepository {
  AuthRepository(this.client);
  final ApiClient client;

  Future<UserSession> login({
    required String phone,
    required String pin,
  }) async {
    try {
      final response = await client.dio.post(
        '/auth/login',
        data: {'phone': phone, 'pin': pin},
      );
      return UserSession.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const ValidationError(
          'INVALID_CREDENTIALS',
          'Invalid phone number or PIN. Check your credentials and try again.',
        );
      }
      throw mapDioError(error);
    }
  }
}
