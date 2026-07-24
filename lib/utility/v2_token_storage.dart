import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sos_auth/sos_auth.dart';

/// A [TokenStorage] that reads/writes the logistics v2 JWT from the same
/// key used by [AppPrefs] (`v2_access_token`).
///
/// [TokenStorage] hardcodes key `sos_auth_token`; this subclass overrides
/// every public method to use the logistics-specific key so that
/// [AuthInterceptor] and [AppPrefs.getV2Token] / [AppPrefs.clearV2] all
/// operate on the same underlying value.
///
/// **Dual-store, secure-first with a SharedPreferences fallback.** The Android
/// encrypted store has repeatedly failed to survive a process restart in this
/// app: writes and same-session reads succeed, but the next launch reads back
/// null, which dropped the user at role selection on every exit and hot restart.
/// The project hit this once before and moved off secure storage entirely (see
/// the "Keystore blocked startup" note in the app CLAUDE.md); mirroring keeps
/// the encrypted copy authoritative wherever it actually works and falls back
/// only when it comes back empty. Trade-off: the JWT is also at rest in plain
/// SharedPreferences, which is the same trade-off this app already documents.
class V2TokenStorage extends TokenStorage {
  static const _kV2Token = 'v2_access_token';

  final FlutterSecureStorage _s;

  V2TokenStorage()
      : _s = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kV2Token, token);
    try {
      await _s.write(key: _kV2Token, value: token);
    } catch (e) {
      debugPrint('[v2token] secure write failed, prefs copy kept: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final v = await _s.read(key: _kV2Token);
      if (v != null && v.isNotEmpty) return v;
      debugPrint('[v2token] secure read empty — falling back to prefs');
    } catch (e) {
      debugPrint('[v2token] secure read failed, falling back to prefs: $e');
    }
    final p = await SharedPreferences.getInstance();
    final fallback = p.getString(_kV2Token);
    if (fallback != null && fallback.isNotEmpty) {
      // Re-seed the encrypted copy so it is authoritative again next launch.
      try {
        await _s.write(key: _kV2Token, value: fallback);
      } catch (_) {}
      return fallback;
    }
    return null;
  }

  @override
  Future<void> clearToken() async {
    try {
      await _s.delete(key: _kV2Token);
    } catch (e) {
      debugPrint('[v2token] secure delete failed: $e');
    }
    final p = await SharedPreferences.getInstance();
    await p.remove(_kV2Token);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
