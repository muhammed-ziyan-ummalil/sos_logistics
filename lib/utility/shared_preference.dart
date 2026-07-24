import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import 'v2_token_storage.dart';

// V2 token goes through [V2TokenStorage] (encrypted store, with a
// SharedPreferences fallback so the session survives a process restart — see
// the note there). Reading/writing the encrypted store directly from here too
// would reintroduce the restart logout for every ApiServiceV2 request, so this
// class MUST delegate rather than keep its own FlutterSecureStorage instance.
// Non-sensitive metadata (name, phone, roles) stays in SharedPreferences.
final _tokenStore = V2TokenStorage();

class AppPrefs {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── V2 Session ───────────────────────────────────────────────────────────────
  static Future<void> saveV2Session({
    required String token,
    required String userId,
    required String name,
    required String phone,
    required List<String> roles,
    required bool mustReset,
    String? ownerId,
    String? ownerStatus,
    String? driverId,
    String? driverStatus,
    required String selectedRole,
  }) async {
    // Token via the shared dual-store
    await _tokenStore.saveToken(token);
    // Non-sensitive metadata in SharedPreferences
    final p = await _prefs;
    await p.setString(StorageKeys.v2UserId, userId);
    await p.setString(StorageKeys.v2UserName, name);
    await p.setString(StorageKeys.v2UserPhone, phone);
    await p.setString(StorageKeys.v2Roles, roles.join(','));
    await p.setBool(StorageKeys.v2MustReset, mustReset);
    if (ownerId != null) await p.setString(StorageKeys.v2OwnerId, ownerId);
    if (ownerStatus != null) await p.setString(StorageKeys.v2OwnerStatus, ownerStatus);
    if (driverId != null) await p.setString(StorageKeys.v2DriverId, driverId);
    if (driverStatus != null) await p.setString(StorageKeys.v2DriverStatus, driverStatus);
    await p.setString(StorageKeys.v2SelectedRole, selectedRole);
  }

  static Future<String?> getV2Token() async => _tokenStore.getToken();

  static Future<bool> getV2MustReset() async =>
      (await _prefs).getBool(StorageKeys.v2MustReset) ?? false;

  static Future<List<String>> getV2Roles() async {
    final s = (await _prefs).getString(StorageKeys.v2Roles) ?? '';
    return s.isEmpty ? [] : s.split(',');
  }

  static Future<String?> getV2SelectedRole() async =>
      (await _prefs).getString(StorageKeys.v2SelectedRole);

  static Future<Map<String, String?>> getV2Session() async {
    final p = await _prefs;
    return {
      'token':        await _tokenStore.getToken(),
      'userId':       p.getString(StorageKeys.v2UserId),
      'name':         p.getString(StorageKeys.v2UserName),
      'phone':        p.getString(StorageKeys.v2UserPhone),
      'roles':        p.getString(StorageKeys.v2Roles),
      'ownerId':      p.getString(StorageKeys.v2OwnerId),
      'ownerStatus':  p.getString(StorageKeys.v2OwnerStatus),
      'driverId':     p.getString(StorageKeys.v2DriverId),
      'driverStatus': p.getString(StorageKeys.v2DriverStatus),
      'selectedRole': p.getString(StorageKeys.v2SelectedRole),
    };
  }

  static Future<void> clearV2() async {
    await _tokenStore.clearToken();
    final p = await _prefs;
    for (final key in [
      StorageKeys.v2UserId, StorageKeys.v2UserName,
      StorageKeys.v2UserPhone, StorageKeys.v2Roles, StorageKeys.v2MustReset,
      StorageKeys.v2OwnerId, StorageKeys.v2OwnerStatus, StorageKeys.v2DriverId,
      StorageKeys.v2DriverStatus, StorageKeys.v2SelectedRole,
    ]) {
      await p.remove(key);
    }
  }

  // ── Clear all (full wipe) ─────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await (await _prefs).clear();
    await _tokenStore.clearToken();
  }
}
