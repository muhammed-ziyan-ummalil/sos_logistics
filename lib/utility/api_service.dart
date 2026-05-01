import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../core/app_constants.dart';
import 'shared_preference.dart';

// ignore_for_file: prefer_single_quotes

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
      final token = await AppPrefs.getActiveToken();
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

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? params,
    bool withToken = true,
  }) async {
    final query = params ?? {};
    if (withToken) {
      final token = await AppPrefs.getActiveToken();
      if (token != null) query['access_token'] = token;
    }
    try {
      final res = await _dio.get(endpoint, queryParameters: query);
      return res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : {'status': 'error', 'message': 'Invalid response'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}

/// V2 API client — uses Authorization: Bearer header + v2BaseUrl
class ApiServiceV2 {
  static ApiServiceV2? _instance;
  late final Dio _dio;

  ApiServiceV2._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.v2BaseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
      validateStatus: (_) => true,
    ));
    _dio.interceptors.add(PrettyDioLogger(requestBody: true, responseBody: true));
  }

  static ApiServiceV2 get instance => _instance ??= ApiServiceV2._();

  Future<Options> _authOptions() async {
    final token = await AppPrefs.getV2Token();
    return Options(headers: token != null ? {'Authorization': 'Bearer $token'} : {});
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool withAuth = true,
  }) async {
    try {
      final opts = withAuth ? await _authOptions() : Options();
      final res = await _dio.post(
        endpoint,
        data: FormData.fromMap(data ?? {}),
        options: opts,
      );
      return res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : {'status': 'error', 'message': 'Invalid response'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? params,
    bool withAuth = true,
  }) async {
    try {
      final opts = withAuth ? await _authOptions() : Options();
      final res = await _dio.get(endpoint, queryParameters: params, options: opts);
      return res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : {'status': 'error', 'message': 'Invalid response'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, dynamic> fields, {
    Map<String, String>? filePaths,
    bool withAuth = true,
  }) async {
    try {
      final formData = FormData();
      fields.forEach((k, v) {
        if (v != null) formData.fields.add(MapEntry(k, v.toString()));
      });
      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          formData.files.add(
            MapEntry(entry.key, await MultipartFile.fromFile(entry.value)),
          );
        }
      }
      final opts = withAuth ? await _authOptions() : Options();
      final res = await _dio.post(endpoint, data: formData, options: opts);
      return res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : {'status': 'error', 'message': 'Invalid response'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
