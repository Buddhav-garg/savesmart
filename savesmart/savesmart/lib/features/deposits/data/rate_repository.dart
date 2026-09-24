import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../domain/rate_card.dart';

class RateRepository {
  RateRepository(this.client);
  final ApiClient client;

  Future<RateCard> getFdRate(int tenureDays) async {
    try {
      final response = await client.dio.get(
        '/deposits/rates',
        queryParameters: {'kind': 'FD', 'tenureDays': tenureDays},
      );
      return RateCard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
