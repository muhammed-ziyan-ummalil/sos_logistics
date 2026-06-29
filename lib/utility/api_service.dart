import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../core/app_constants.dart';
import 'shared_preference.dart';
// ignore_for_file: prefer_single_quotes

/// Unified V2 API client — for /api/v2/* endpoints (capGuard-protected).
/// Uses same JWT token as [ApiServiceV2] but targets the unified API base.
class ApiServiceUnified {
  static ApiServiceUnified? _instance;
  late final Dio _dio;

  ApiServiceUnified._() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.sossss.net/api/v2/',
      connectTimeout: const Duration(seconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
      validateStatus: (_) => true,
    ));

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

    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) async {
        if (response.statusCode == 401) {
          await ApiServiceV2._handleUnauthorized();
        }
        handler.next(response);
      },
    ));

    _dio.interceptors.add(PrettyDioLogger(requestBody: true, responseBody: true));
  }

  static ApiServiceUnified get instance => _instance ??= ApiServiceUnified._();

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

  // --- Named delivery feed helpers ---

  Future<Map<String, dynamic>> getDeliveryFeed() =>
      get('owner/delivery-feed');

  Future<Map<String, dynamic>> getDeliveryFeedDetail(int id) =>
      get('owner/delivery-feed/$id');

  Future<Map<String, dynamic>> submitDeliveryQuote(int requestId, int vehicleId) =>
      post('owner/delivery-quote', data: {'request_id': requestId, 'vehicle_id': vehicleId});

  Future<Map<String, dynamic>> getMyQuotes() =>
      get('owner/my-quotes');

  Future<Map<String, dynamic>> getQuoteVehicles(int requestId) =>
      post('owner/quote-vehicles', data: {'request_id': requestId});

  // --- On-demand driver OTP methods ---
  // These resolve to api/v2/delivery/* (capGuard:driver). They live on this
  // client because the legacy api/logistics/v2/* group does NOT expose them.

  Future<Map<String, dynamic>> generatePickupOtp(int deliveryId) =>
      post('delivery/generate-pickup-otp', data: {'delivery_id': deliveryId});

  Future<Map<String, dynamic>> verifyPickupOtp(int deliveryId, String otp) =>
      post('delivery/verify-pickup-otp', data: {'delivery_id': deliveryId, 'otp': otp});

  Future<Map<String, dynamic>> generateDropOtp(int deliveryId) =>
      post('delivery/generate-drop-otp', data: {'delivery_id': deliveryId});

  Future<Map<String, dynamic>> verifyDropOtp(int deliveryId, String otp) =>
      post('delivery/verify-drop-otp', data: {'delivery_id': deliveryId, 'otp': otp});

  Future<Map<String, dynamic>> resendPickupOtp(int deliveryId) =>
      post('delivery/resend-pickup-otp', data: {'delivery_id': deliveryId});

  Future<Map<String, dynamic>> resendDropOtp(int deliveryId) =>
      post('delivery/resend-drop-otp', data: {'delivery_id': deliveryId});

  // --- In-app notifications (owner + driver) ---
  // role is 'owner' or 'driver' -> api/v2/{role}/notifications/*

  Future<Map<String, dynamic>> getNotifications(String role) =>
      post('$role/notifications/get');

  Future<Map<String, dynamic>> getNotificationSummary(String role) =>
      post('$role/notifications/summary');

  Future<Map<String, dynamic>> markNotificationsRead(String role,
          {int? notificationId, bool markAll = false}) =>
      post('$role/notifications/mark-read', data: {
        if (notificationId != null) 'notification_id': notificationId,
        'mark_all': markAll ? 1 : 0,
      });
}

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
    // Route to role selection (not login) so an owner whose session expired
    // is not forced into the driver-login framing (login defaults role=driver).
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
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
