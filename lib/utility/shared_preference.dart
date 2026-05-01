import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_constants.dart';

class AppPrefs {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: StorageKeys.accessToken);

  static Future<void> saveDriverInfo({
    required String name,
    required String phone,
    required String id,
  }) async {
    await _storage.write(key: StorageKeys.driverName, value: name);
    await _storage.write(key: StorageKeys.driverPhone, value: phone);
    await _storage.write(key: StorageKeys.driverId, value: id);
  }

  static Future<Map<String, String?>> getDriverInfo() async => {
    'name':  await _storage.read(key: StorageKeys.driverName),
    'phone': await _storage.read(key: StorageKeys.driverPhone),
    'id':    await _storage.read(key: StorageKeys.driverId),
  };

  static Future<void> clearAll() => _storage.deleteAll();
}
