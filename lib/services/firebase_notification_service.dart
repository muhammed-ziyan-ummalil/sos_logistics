import 'package:firebase_messaging/firebase_messaging.dart';
import '../utility/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

class FirebaseNotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, sound: true, badge: true);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> uploadToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await ApiService.instance.post(
      'driver/update-firebase-token',
      data: {'firebase_token': token},
    );
  }
}
