import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';
  static const String _notificationsKey = 'push_notifications';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  String _language = 'en';
  bool _isDarkMode = true;
  bool _pushNotificationsEnabled = true;

  // Getters
  String get language => _language;
  bool get isDarkMode => _isDarkMode;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get isInitialized => _isInitialized;

  // Initialize settings from storage
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _language = _prefs.getString(_languageKey) ?? 'en';
    _isDarkMode = _prefs.getBool(_themeKey) ?? true;
    _pushNotificationsEnabled = _prefs.getBool(_notificationsKey) ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  // Set language
  Future<void> setLanguage(String language) async {
    if (_language != language) {
      _language = language;
      await _prefs.setString(_languageKey, language);
      notifyListeners();
    }
  }

  // Set dark mode
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _prefs.setBool(_themeKey, isDark);
      notifyListeners();
    }
  }

  // Set push notifications
  Future<void> setPushNotifications(bool enabled) async {
    if (_pushNotificationsEnabled != enabled) {
      _pushNotificationsEnabled = enabled;
      await _prefs.setBool(_notificationsKey, enabled);
      notifyListeners();
    }
  }

  // Get available languages
  static List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'om', 'name': 'Afaan Oromoo'},
    ];
  }

  // Get language name
  static String getLanguageName(String code) {
    final lang = getAvailableLanguages().firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'code': 'en', 'name': 'English'},
    );
    return lang['name'] ?? 'English';
  }
}
