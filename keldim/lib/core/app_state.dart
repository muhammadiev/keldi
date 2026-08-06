import 'package:flutter/material.dart';

import '../services/storage.dart';
import '../services/api_service.dart';
import '../models/models.dart';

/// App-wide state: theme mode + current user. A lightweight ChangeNotifier
/// singleton (no external state-management dependency).
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  UserProfile? _user;
  UserProfile? get user => _user;
  bool get isAdmin => _user?.isStaff ?? false;

  Future<void> load() async {
    final t = await Storage.themeMode;
    _themeMode = switch (t) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await Storage.setThemeMode(switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    notifyListeners();
  }

  void setUser(UserProfile? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final res = await ApiService.getProfile();
    if (res.ok) setUser(res.data);
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }
}
