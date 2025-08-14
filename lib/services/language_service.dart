import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  // Default language is Bahasa Melayu
  static const String _defaultLanguage = 'ms';
  
  /// Get the saved language preference
  static Future<String> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _defaultLanguage;
  }
  
  /// Save language preference
  static Future<void> saveSelectedLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
  
  /// Get locale from language code
  static Locale getLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en');
      case 'ms':
        return const Locale('ms');
      default:
        return const Locale('ms'); // Default to Bahasa Melayu
    }
  }
  
  /// Get available locales
  static List<Locale> getSupportedLocales() {
    return const [
      Locale('ms'), // Bahasa Melayu (default)
      Locale('en'), // English
    ];
  }
  
  /// Get language name for display
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ms':
        return 'Bahasa Melayu';
      default:
        return 'Bahasa Melayu';
    }
  }
  
  /// Get localized prayer name
  static String getLocalizedPrayerName(String prayerName, String languageCode) {
    if (languageCode == 'ms') {
      switch (prayerName.toLowerCase()) {
        case 'fajr':
          return 'Subuh';
        case 'dhuhr':
          return 'Zohor';
        case 'asr':
          return 'Asar';
        case 'maghrib':
          return 'Maghrib';
        case 'isha':
          return 'Isyak';
        default:
          return prayerName;
      }
    }
    return prayerName; // Return original for English
  }
}
