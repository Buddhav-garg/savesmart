import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savesmart/core/errors/bank_error.dart';
import 'package:savesmart/core/network/error_mapper.dart';

void main() {
  DioException responseError(int status, {Object? data}) => DioException(
    requestOptions: RequestOptions(path: '/test'),
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: status,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );

  test('maps unauthorized responses to a readable sign-in error', () {
    final error = mapDioError(responseError(401));

    expect(error, isA<UnauthenticatedError>());
    expect(error.toString(), contains('Sign in again'));
  });

  test('maps forbidden responses to an access error', () {
    expect(mapDioError(responseError(403)), isA<ForbiddenError>());
  });

  test('preserves the server validation message', () {
    final error = mapDioError(
      responseError(422, data: {
        'error': {'code': 'INVALID_AMOUNT', 'message': 'Amount is too low.'},
      }),
    );

    expect(error, isA<ValidationError>());
    expect(error.message, 'Amount is too low.');
  });

  test('maps service failures without exposing raw server data', () {
    expect(mapDioError(responseError(503)), isA<ServerError>());
  });
}
