import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utility/v2_token_storage.dart';

// ─── Notification channel constants ──────────────────────────────────────────

const _kChannelId = 'sos_logistics_channel';
const _kChannelName = 'SOS Logistics';
const _kChannelDesc = 'Driver & owner delivery notifications';

// ─── flutter_local_notifications singletons ──────────────────────────────────

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  _kChannelId,
  _kChannelName,
  description: _kChannelDesc,
  importance: Importance.high,
);

// ─── Service ─────────────────────────────────────────────────────────────────

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Guard against concurrent token-sync calls.
  static bool _tokenSyncInProgress = false;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Call once in main() AFTER Firebase.initializeApp().
  static Future<void> init() async {
    await _requestPermission();
    await _initLocalNotification();
    _listenFirebaseMessages();
    _listenTokenRefresh();
    await _syncTokenToBackend();
  }

  /// Call after a successful login so the freshly-authenticated device
  /// registers its FCM token with the backend immediately.
  static Future<void> syncTokenAfterLogin() async {
    await _syncTokenToBackend();
  }

  /// Used by the top-level background handler (registered with pragma) to show
  /// a local notification for data-only messages (no notification block).
  static Future<void> showFromBackground(RemoteMessage message) async {
    await _showNotification(message);
  }

  // ─── Permission ────────────────────────────────────────────────────────────

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ─── Local notification init ────────────────────────────────────────────────

  static Future<void> _initLocalNotification() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
    );

    // Create the high-importance Android channel required for heads-up display.
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // ─── Firebase listeners ─────────────────────────────────────────────────────

  static void _listenFirebaseMessages() {
    // FOREGROUND: FCM never auto-displays while the app is in foreground,
    // so we always show a local notification here. No duplication risk —
    // the system tray only auto-shows in background/killed (background handler).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // BACKGROUND/KILLED → tapped: app was opened by tapping a notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // No specific navigation in logistics right now; extend here as needed.
    });
  }

  // ─── Show local notification ────────────────────────────────────────────────

  static Future<void> _showNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ─── Killed-state message (app opened from terminated state) ───────────────

  static Future<void> handleKilledState() async {
    final RemoteMessage? message = await _messaging.getInitialMessage();
    if (message != null) {
      // App was opened via FCM notification while terminated — handle routing
      // here as needed.
    }
  }

  // ─── Token sync ─────────────────────────────────────────────────────────────

  static void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (token.isNotEmpty) {
        await _syncTokenToBackend(token: token);
      }
    });
  }

  /// POST the FCM token to `auth/update-firebase-token` (unified auth endpoint).
  ///
  /// Uses the UNIFIED base URL (https://api.sossss.net/api/) — NOT the v2/
  /// sub-path — because `auth/update-firebase-token` lives on the unified auth
  /// controller, same one used by login/me/add-capability.
  ///
  /// Guarded by login state: skips silently when no JWT is present (avoids
  /// forcing a 401 logout on the Dio interceptor before the user has logged in).
  static Future<void> _syncTokenToBackend({String? token}) async {
    if (_tokenSyncInProgress) return;

    final jwt = await V2TokenStorage().getToken();
    if (jwt == null || jwt.isEmpty) return; // not logged in yet

    final pushToken = token ?? await _messaging.getToken();
    if (pushToken == null || pushToken.isEmpty) return;

    try {
      _tokenSyncInProgress = true;

      // Build a minimal one-shot Dio client pointed at the unified auth base.
      // We cannot reuse ApiServiceUnified (base: /api/v2/) or ApiServiceV2
      // (base: AppConstants.v2BaseUrl) because this endpoint lives at /api/.
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.sossss.net/api/',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (_) => true,
      ));
      dio.options.headers['Authorization'] = 'Bearer $jwt';

      await dio.post(
        'auth/update-firebase-token',
        data: {'firebase_token': pushToken},
      );
    } catch (_) {
      // Best-effort; ignore network/auth failures.
    } finally {
      _tokenSyncInProgress = false;
    }
  }
}
