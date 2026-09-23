import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../domain/goal.dart';

class GoalRepository {
  GoalRepository(this.client);
  final ApiClient client;

  Future<List<Goal>> listGoals() async {
    try {
      final response = await client.dio.get('/goals');
      final items = (response.data['items'] as List)
          .cast<Map<String, dynamic>>();
      return items.map(Goal.fromJson).toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Goal> createGoal({
    required String name,
    required String icon,
    required int targetPaise,
    required DateTime targetDate,
  }) async {
    try {
      final response = await client.dio.post(
        '/goals',
        data: {
          'name': name,
          'icon': icon,
          'targetPaise': targetPaise,
          'targetDate': targetDate.toIso8601String().substring(0, 10),
        },
      );
      return Goal.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
