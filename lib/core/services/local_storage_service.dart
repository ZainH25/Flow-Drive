import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  bool get isOnboardingCompleted =>
      _prefs.getBool(StorageKeys.onboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted({required bool value}) async {
    await _prefs.setBool(StorageKeys.onboardingCompleted, value);
  }

  String? get devUserEmail => _prefs.getString(StorageKeys.devUserEmail);

  Future<void> setDevUserEmail(String email) async {
    await _prefs.setString(StorageKeys.devUserEmail, email);
  }

  Future<void> clearDevUserEmail() async {
    await _prefs.remove(StorageKeys.devUserEmail);
  }

  bool get rememberMe => _prefs.getBool(StorageKeys.rememberMe) ?? false;

  String? get rememberedEmail => _prefs.getString(StorageKeys.rememberedEmail);

  Future<void> setRememberMe(bool value) async {
    await _prefs.setBool(StorageKeys.rememberMe, value);
  }

  Future<void> setRememberedEmail(String email) async {
    await _prefs.setString(StorageKeys.rememberedEmail, email);
  }

  Future<void> clearRememberedEmail() async {
    await _prefs.remove(StorageKeys.rememberedEmail);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
