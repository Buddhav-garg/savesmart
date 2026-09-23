import 'package:dio/dio.dart';

import '../errors/bank_error.dart';

BankError mapDioError(DioException error) {
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const NetworkError();
  }
  final data = error.response?.data;
  final envelope = data is Map ? data['error'] : null;
  final code = envelope is Map ? envelope['code'] as String? : null;
  final message = envelope is Map
      ? envelope['message'] as String? ?? 'Something went wrong.'
      : 'Something went wrong.';
  if (error.response?.statusCode == 401 || code == 'UNAUTHENTICATED') {
    return const UnauthenticatedError();
  }
  return ValidationError(code ?? 'UNKNOWN', message);
}
