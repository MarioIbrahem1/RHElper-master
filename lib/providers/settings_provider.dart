import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _localeKey = 'current_locale';
  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;

  SettingsProvider() {
    _loadLocale();
  }

  /// Load the saved locale preference
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLocale = prefs.getString(_localeKey) ?? 'en';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  /// Change the app locale and save the preference
  Future<void> changeLocale(String newLocale) async {
    if (newLocale == _currentLocale) return;
    
    _currentLocale = newLocale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale);
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
  }
}
