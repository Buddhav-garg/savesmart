import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../domain/deposit.dart';

class DepositRepository {
  DepositRepository(this.client);
  final ApiClient client;

  Future<List<Deposit>> listDeposits({String sort = 'maturityDate'}) async {
    try {
      final response = await client.dio.get(
        '/deposits',
        queryParameters: {'sort': sort, 'order': 'asc'},
      );
      final items = (response.data['items'] as List)
          .cast<Map<String, dynamic>>();
      return items.map(Deposit.fromJson).toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Deposit> book({
    required String kind,
    required int tenureDays,
    int? principalPaise,
    int? installmentPaise,
    int? debitDate,
    String? nomineeName,
    String? nomineeRelation,
    int? nomineeSharePct,
    String payout = 'on_maturity',
    String renewal = 'none',
    required String idempotencyKey,
  }) async {
    try {
      final data = <String, dynamic>{
        'kind': kind,
        'tenureDays': tenureDays,
        'payout': payout,
        'renewal': renewal,
      };
      if (principalPaise != null) data['principalPaise'] = principalPaise;
      if (installmentPaise != null) {
        data['installmentPaise'] = installmentPaise;
      }
      if (debitDate != null) data['debitDate'] = debitDate;
      if (nomineeName != null) {
        data['nominee'] = {
          'name': nomineeName,
          'relation': nomineeRelation,
          'sharePct': nomineeSharePct,
        };
      }
      final response = await client.dio.post(
        '/deposits',
        data: data,
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return Deposit.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Map<String, dynamic>> withdrawalQuote(String depositId) async {
    try {
      final response = await client.dio.post(
        '/deposits/$depositId/withdrawal-quote',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Map<String, dynamic>> withdraw(
    String depositId,
    String quoteId,
  ) async {
    try {
      final response = await client.dio.post(
        '/deposits/$depositId/withdraw',
        data: {'quoteId': quoteId},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
