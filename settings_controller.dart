import 'package:flutter/material.dart';
import 'local_storage_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  AppSettings _settings = AppSettings.defaults;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  AppSettings get settings => _settings;

  bool get darkMode => _settings.darkMode;
  bool get notificationsEnabled => _settings.notificationsEnabled;
  String get languageCode => _settings.languageCode;

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _settings = LocalStorageService.instance.getSettings();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _settings = _settings.copyWith(darkMode: value);
    notifyListeners(); // immediate UI update
    await LocalStorageService.instance.setDarkMode(value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _settings = _settings.copyWith(notificationsEnabled: value);
    notifyListeners();
    await LocalStorageService.instance.setNotificationsEnabled(value);
  }

  Future<void> setLanguageCode(String value) async {
    _settings = _settings.copyWith(languageCode: value);
    notifyListeners();
    await LocalStorageService.instance.setLanguageCode(value);
  }

  Future<void> resetToDefaults() async {
    _settings = AppSettings.defaults;
    notifyListeners();
    await LocalStorageService.instance.saveSettings(_settings);
  }
}
