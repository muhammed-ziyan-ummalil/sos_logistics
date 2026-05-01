import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';

class AppPrefs {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Driver ───────────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async =>
      (await _prefs).setString(StorageKeys.accessToken, token);

  static Future<String?> getToken() async =>
      (await _prefs).getString(StorageKeys.accessToken);

  static Future<void> saveDriverInfo({
    required String name,
    required String phone,
    required String id,
  }) async {
    final p = await _prefs;
    await p.setString(StorageKeys.driverName, name);
    await p.setString(StorageKeys.driverPhone, phone);
    await p.setString(StorageKeys.driverId, id);
  }

  static Future<Map<String, String?>> getDriverInfo() async {
    final p = await _prefs;
    return {
      'name':  p.getString(StorageKeys.driverName),
      'phone': p.getString(StorageKeys.driverPhone),
      'id':    p.getString(StorageKeys.driverId),
    };
  }

  // ── Owner ────────────────────────────────────────────────────────────────────
  static Future<void> saveOwnerToken(String token) async =>
      (await _prefs).setString(StorageKeys.ownerAccessToken, token);

  static Future<String?> getOwnerToken() async =>
      (await _prefs).getString(StorageKeys.ownerAccessToken);

  static Future<void> saveOwnerInfo({
    required String name,
    required String phone,
    required String id,
  }) async {
    final p = await _prefs;
    await p.setString(StorageKeys.ownerName, name);
    await p.setString(StorageKeys.ownerPhone, phone);
    await p.setString(StorageKeys.ownerId, id);
  }

  static Future<Map<String, String?>> getOwnerInfo() async {
    final p = await _prefs;
    return {
      'name':  p.getString(StorageKeys.ownerName),
      'phone': p.getString(StorageKeys.ownerPhone),
      'id':    p.getString(StorageKeys.ownerId),
    };
  }

  // ── Role ─────────────────────────────────────────────────────────────────────
  static Future<void> saveUserRole(String role) async =>
      (await _prefs).setString(StorageKeys.userRole, role);

  static Future<String?> getUserRole() async =>
      (await _prefs).getString(StorageKeys.userRole);

  // ── Active token (role-aware, used by ApiService) ────────────────────────────
  static Future<String?> getActiveToken() async {
    final role = await getUserRole();
    return role == UserRole.owner ? getOwnerToken() : getToken();
  }

  // ── Clear ────────────────────────────────────────────────────────────────────
  static Future<void> clearAll() async => (await _prefs).clear();

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
    final p = await _prefs;
    await p.setString(StorageKeys.v2Token, token);
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

  static Future<String?> getV2Token() async =>
      (await _prefs).getString(StorageKeys.v2Token);

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
      'token':        p.getString(StorageKeys.v2Token),
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
    final p = await _prefs;
    for (final key in [
      StorageKeys.v2Token, StorageKeys.v2UserId, StorageKeys.v2UserName,
      StorageKeys.v2UserPhone, StorageKeys.v2Roles, StorageKeys.v2MustReset,
      StorageKeys.v2OwnerId, StorageKeys.v2OwnerStatus, StorageKeys.v2DriverId,
      StorageKeys.v2DriverStatus, StorageKeys.v2SelectedRole,
    ]) {
      await p.remove(key);
    }
  }
}
