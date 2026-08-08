import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for tokens and simple settings.
///
/// NOTE: for production, the auth token is better kept in flutter_secure_storage.
/// SharedPreferences is used here to stay dependency-light.
class Storage {
  static const _kToken = 'auth_token';
  static const _kRole = 'role';
  static const _kName = 'full_name';
  static const _kBaseUrl = 'base_url';
  static const _kThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'

  static SharedPreferences? _p;
  static Future<SharedPreferences> get _prefs async =>
      _p ??= await SharedPreferences.getInstance();

  static Future<String?> get token async => (await _prefs).getString(_kToken);
  static Future<void> setToken(String? v) async {
    final p = await _prefs;
    if (v == null) {
      await p.remove(_kToken);
    } else {
      await p.setString(_kToken, v);
    }
  }

  static Future<String?> get role async => (await _prefs).getString(_kRole);
  static Future<void> setRole(String v) async =>
      (await _prefs).setString(_kRole, v);

  static Future<String?> get name async => (await _prefs).getString(_kName);
  static Future<void> setName(String v) async =>
      (await _prefs).setString(_kName, v);

  static Future<String?> get baseUrl async =>
      (await _prefs).getString(_kBaseUrl);
  static Future<void> setBaseUrl(String v) async =>
      (await _prefs).setString(_kBaseUrl, v);

  static Future<String> get themeMode async =>
      (await _prefs).getString(_kThemeMode) ?? 'system';
  static Future<void> setThemeMode(String v) async =>
      (await _prefs).setString(_kThemeMode, v);

  static Future<void> clearSession() async {
    final p = await _prefs;
    await p.remove(_kToken);
    await p.remove(_kRole);
    await p.remove(_kName);
  }
}
