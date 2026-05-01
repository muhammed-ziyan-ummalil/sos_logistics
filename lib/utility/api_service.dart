import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../core/app_constants.dart';
import 'shared_preference.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: Duration(seconds: AppConstants.connectTimeout),
      receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
      validateStatus: (_) => true,
    ));
    _dio.interceptors.add(PrettyDioLogger(requestBody: true, responseBody: true));
  }

  static ApiService get instance => _instance ??= ApiService._();

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool withToken = true,
  }) async {
    final body = data ?? {};
    if (withToken) {
      final token = await AppPrefs.getToken();
      if (token != null) body['access_token'] = token;
    }
    try {
      final res = await _dio.post(endpoint, data: FormData.fromMap(body));
      return res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : {'status': 'error', 'message': 'Invalid response'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
