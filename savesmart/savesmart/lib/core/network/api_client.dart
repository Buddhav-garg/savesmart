import 'package:dio/dio.dart';

import 'api_config.dart';

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  static String? _token;

  void setToken(String? token) => _token = token;
}
