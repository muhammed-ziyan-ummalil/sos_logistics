import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../core/app_constants.dart';
import 'shared_preference.dart';
// ignore_for_file: prefer_single_quotes

/// V2 API client — JWT auth with custom interceptors.
///
/// Token attachment: custom onRequest interceptor checks `extra['withAuth']`
/// flag — requests made with `withAuth: false` do NOT get an Authorization
/// header even if a token is stored (fixes login-flow 401 pollution).
///
/// 401 handling: guarded by [_handleUnauthorized] which checks token presence
/// first — login failures (no active session) are silently ignored.
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

    // Token-attachment interceptor: reads V2TokenStorage and attaches the
    // Authorization header only when `options.extra['withAuth'] != false`.
    // This ensures `withAuth: false` requests (e.g. login) never carry a
    // stale token even if one exists in storage.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['withAuth'] != false) {
          final token = await AppPrefs.getV2Token();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ));

    // 401 logout handler — required because validateStatus: (_) => true means
    // 401 responses are delivered as successful responses, not DioExceptions.
    // Guard prevents acting on login-failure 401s (no active session).
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) async {
        if (response.statusCode == 401) {
          await _handleUnauthorized();
        }
        handler.next(response);
      },
    ));

    _dio.interceptors.add(PrettyDioLogger(requestBody: true, responseBody: true));
  }

  static ApiServiceV2 get instance => _instance ??= ApiServiceV2._();

  static Future<void> _handleUnauthorized() async {
    final token = await AppPrefs.getV2Token();
    if (token == null || token.isEmpty) return; // not a session expiry — ignore
    await AppPrefs.clearV2();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool withAuth = true,
  }) async {
    try {
      final res = await _dio.post(
        endpoint,
        data: FormData.fromMap(data ?? {}),
        options: withAuth ? null : Options(extra: {'withAuth': false}),
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
      final res = await _dio.get(
        endpoint,
        queryParameters: params,
        options: withAuth ? null : Options(extra: {'withAuth': false}),
      );
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
      final res = await _dio.post(
        endpoint,
        data: formData,
        options: withAuth ? null : Options(extra: {'withAuth': false}),
      );
      return res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : {'status': 'error', 'message': 'Invalid response'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
