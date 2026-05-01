import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utility/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

class FirebaseNotificationService {
  static final _messaging     = FirebaseMessaging.instance;
  static final _localNotif    = FlutterLocalNotificationsPlugin();
  static const _channelId     = 'logistics_offers';
  static const _channelName   = 'Delivery Offers';

  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, sound: true, badge: true);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.max,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _localNotif.show(
        0,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  static Future<void> uploadToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await ApiService.instance.post('driver/update-firebase-token', data: {'firebase_token': token});
  }
}
