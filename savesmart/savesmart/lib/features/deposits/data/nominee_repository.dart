import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../domain/nominee.dart';

class NomineeRepository {
  NomineeRepository(this.client);
  final ApiClient client;

  Future<List<Nominee>> list() async {
    try {
      final response = await client.dio.get('/account/nominees');
      final items = (response.data['items'] as List)
          .cast<Map<String, dynamic>>();
      return items.map(Nominee.fromJson).toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<Nominee>> save(List<Nominee> nominees) async {
    try {
      final response = await client.dio.put(
        '/account/nominees',
        data: {
          'items': nominees
              .map(
                (nominee) => {
                  'name': nominee.name,
                  'relation': nominee.relation,
                  'sharePct': nominee.sharePct,
                },
              )
              .toList(),
        },
      );
      final items = (response.data['items'] as List)
          .cast<Map<String, dynamic>>();
      return items.map(Nominee.fromJson).toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
