import 'package:dio/dio.dart';

import '../errors/bank_error.dart';

BankError mapDioError(DioException error) {
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.badCertificate) {
    return const NetworkError();
  }
  final data = error.response?.data;
  final envelope = data is Map ? data['error'] : null;
  final code = envelope is Map ? envelope['code']?.toString() : null;
  final message = envelope is Map
      ? envelope['message']?.toString() ?? 'Something went wrong.'
      : data is Map
      ? data['message']?.toString() ?? 'Something went wrong.'
      : 'Something went wrong.';
  final status = error.response?.statusCode;
  if (status == 401 || code == 'UNAUTHENTICATED') {
    return const UnauthenticatedError();
  }
  if (status == 403 || code == 'FORBIDDEN') return const ForbiddenError();
  if (status == 404 || code == 'NOT_FOUND') return const NotFoundError();
  if (status == 408) return const NetworkError();
  if (status != null && status >= 500) return const ServerError();
  if (status == 400 || status == 422) {
    return ValidationError(code ?? 'VALIDATION', message);
  }
  return UnknownError(message);
}
