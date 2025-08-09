import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _selectedZoneKey = 'selected_zone';
  static const String _defaultZone = 'WLY01';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _adzanEnabledKey = 'adzan_enabled';

  // Save selected zone to preferences
  static Future<void> saveSelectedZone(String zoneCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedZoneKey, zoneCode);
  }

  // Load selected zone from preferences
  static Future<String> getSelectedZone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedZoneKey) ?? _defaultZone;
  }

  // Notification preferences
  static Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Default enabled
  }

  // Adzan preferences
  static Future<void> saveAdzanEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adzanEnabledKey, enabled);
  }

  static Future<bool> getAdzanEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adzanEnabledKey) ?? true; // Default enabled
  }

  // Clear all preferences
  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
