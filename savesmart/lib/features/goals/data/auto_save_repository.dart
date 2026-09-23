import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../domain/auto_save_rule.dart';

class AutoSaveRepository {
  AutoSaveRepository(this.client);
  final ApiClient client;

  Future<List<AutoSaveRule>> createRule({
    required String goalId,
    required String type,
    int? amountPaise,
    double? percent,
    String? schedule,
  }) async {
    try {
      final data = <String, dynamic>{'type': type};
      if (amountPaise != null) data['amountPaise'] = amountPaise;
      if (percent != null) data['percent'] = percent;
      if (schedule != null) data['schedule'] = schedule;
      final response = await client.dio.put('/goals/$goalId/rules', data: data);
      final items = (response.data['items'] as List)
          .cast<Map<String, dynamic>>();
      return items.map(AutoSaveRule.fromJson).toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<AutoSaveRule> setPaused({
    required String goalId,
    required String ruleId,
    required bool paused,
  }) async {
    try {
      final response = await client.dio.patch(
        '/goals/$goalId/rules/$ruleId',
        data: {'paused': paused},
      );
      return AutoSaveRule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
