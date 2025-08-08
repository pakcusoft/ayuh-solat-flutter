import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _selectedZoneKey = 'selected_zone';
  static const String _defaultZone = 'WLY01';

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

  // Clear all preferences
  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
