import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sos_auth/sos_auth.dart';

/// A [TokenStorage] that reads/writes the logistics v2 JWT from the same
/// secure-storage key used by [AppPrefs] (`v2_access_token`).
///
/// [TokenStorage] hardcodes key `sos_auth_token`; this subclass overrides
/// every public method to use the logistics-specific key so that
/// [AuthInterceptor] and [AppPrefs.getV2Token] / [AppPrefs.clearV2] all
/// operate on the same underlying value.
class V2TokenStorage extends TokenStorage {
  static const _kV2Token = 'v2_access_token';

  final FlutterSecureStorage _s;

  V2TokenStorage()
      : _s = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<void> saveToken(String token) => _s.write(key: _kV2Token, value: token);

  @override
  Future<String?> getToken() => _s.read(key: _kV2Token);

  @override
  Future<void> clearToken() => _s.delete(key: _kV2Token);

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
