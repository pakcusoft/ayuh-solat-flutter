import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_time.dart';

class DatabaseService {
  static SharedPreferences? _prefs;
  static const String _prayerTimesPrefix = 'prayer_times_';
  static const String _metadataPrefix = 'cache_metadata_';

  // Get SharedPreferences instance
  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Save multiple prayer times for a zone and date range
  static Future<void> savePrayerTimes(
    String zone,
    List<PrayerTime> prayerTimes,
    String bearing,
    String serverTime,
  ) async {
    if (prayerTimes.isEmpty) return;

    final prefs = await _preferences;
    
    for (final prayerTime in prayerTimes) {
      final key = '$_prayerTimesPrefix${zone}_${prayerTime.date}';
      final data = {
        'zone': zone,
        'date': prayerTime.date,
        'hijri': prayerTime.hijri,
        'day': prayerTime.day,
        'imsak': prayerTime.imsak,
        'fajr': prayerTime.fajr,
        'syuruk': prayerTime.syuruk,
        'dhuha': prayerTime.dhuha,
        'dhuhr': prayerTime.dhuhr,
        'asr': prayerTime.asr,
        'maghrib': prayerTime.maghrib,
        'isha': prayerTime.isha,
        'bearing': bearing,
        'server_time': serverTime,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(key, jsonEncode(data));
    }
  }

  // Get prayer time for a specific zone and date
  static Future<PrayerTime?> getPrayerTimeForDate(String zone, String date) async {
    final prefs = await _preferences;
    final key = '$_prayerTimesPrefix${zone}_$date';
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return null;
    
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return PrayerTime(
        hijri: data['hijri'] as String,
        date: data['date'] as String,
        day: data['day'] as String,
        imsak: data['imsak'] as String,
        fajr: data['fajr'] as String,
        syuruk: data['syuruk'] as String,
        dhuha: data['dhuha'] as String,
        dhuhr: data['dhuhr'] as String,
        asr: data['asr'] as String,
        maghrib: data['maghrib'] as String,
        isha: data['isha'] as String,
      );
    } catch (e) {
      return null;
    }
  }

  // Get cached prayer time response for today
  static Future<PrayerTimeResponse?> getTodaysPrayerTime(String zone) async {
    final today = DateTime.now();
    final dateStr = '${today.day.toString().padLeft(2, '0')}-${_getMonthName(today.month)}-${today.year}';
    
    final prayerTime = await getPrayerTimeForDate(zone, dateStr);
    if (prayerTime == null) return null;

    // Get bearing from metadata or try to get from any cached prayer time
    String bearing = '';
    String serverTime = '';
    
    final metadata = await getCacheMetadata(zone);
    if (metadata != null) {
      final prefs = await _preferences;
      final keys = prefs.getKeys().where((key) => key.startsWith('$_prayerTimesPrefix$zone')).toList();
      
      if (keys.isNotEmpty) {
        final firstKey = keys.first;
        final jsonString = prefs.getString(firstKey);
        if (jsonString != null) {
          try {
            final data = jsonDecode(jsonString) as Map<String, dynamic>;
            bearing = data['bearing'] as String? ?? '';
            serverTime = data['server_time'] as String? ?? '';
          } catch (e) {
            // Ignore error, use empty values
          }
        }
      }
    }

    return PrayerTimeResponse(
      prayerTimes: [prayerTime],
      status: 'OK! (Cached)',
      serverTime: serverTime,
      periodType: 'today',
      language: 'ms_my',
      zone: zone,
      bearing: bearing,
    );
  }

  // Update cache metadata
  static Future<void> updateCacheMetadata({
    required String zone,
    required DateTime lastUpdated,
    required DateTime nextUpdate,
    required String dataStartDate,
    required String dataEndDate,
  }) async {
    final prefs = await _preferences;
    final key = '$_metadataPrefix$zone';
    final data = {
      'zone': zone,
      'last_updated': lastUpdated.toIso8601String(),
      'next_update': nextUpdate.toIso8601String(),
      'data_start_date': dataStartDate,
      'data_end_date': dataEndDate,
    };
    
    await prefs.setString(key, jsonEncode(data));
  }

  // Get cache metadata for a zone
  static Future<Map<String, dynamic>?> getCacheMetadata(String zone) async {
    final prefs = await _preferences;
    final key = '$_metadataPrefix$zone';
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Check if cache needs update for a zone
  static Future<bool> needsCacheUpdate(String zone) async {
    final metadata = await getCacheMetadata(zone);
    if (metadata == null) return true;

    final nextUpdate = DateTime.parse(metadata['next_update'] as String);
    return DateTime.now().isAfter(nextUpdate);
  }

  // Clean old data (older than 2 months)
  static Future<void> cleanOldData() async {
    final prefs = await _preferences;
    final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
    final keys = prefs.getKeys().where((key) => key.startsWith(_prayerTimesPrefix)).toList();
    
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        try {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          final createdAt = DateTime.parse(data['created_at'] as String);
          if (createdAt.isBefore(twoMonthsAgo)) {
            await prefs.remove(key);
          }
        } catch (e) {
          // If there's an error parsing, remove the key to clean up corrupted data
          await prefs.remove(key);
        }
      }
    }
  }

  // Get prayer times for a date range
  static Future<List<PrayerTime>> getPrayerTimesForDateRange(
    String zone,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final prefs = await _preferences;
    final List<PrayerTime> prayerTimes = [];
    
    // Iterate through each day in the range
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dateStr = '${currentDate.day.toString().padLeft(2, '0')}-${_getMonthName(currentDate.month)}-${currentDate.year}';
      final prayerTime = await getPrayerTimeForDate(zone, dateStr);
      
      if (prayerTime != null) {
        prayerTimes.add(prayerTime);
      }
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return prayerTimes;
  }
  
  // Helper method to get month name from API format
  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Get available date range for a zone
  static Future<Map<String, String>?> getDataRange(String zone) async {
    final prefs = await _preferences;
    final keys = prefs.getKeys().where((key) => key.startsWith('$_prayerTimesPrefix$zone')).toList();
    
    if (keys.isEmpty) return null;
    
    final dates = <String>[];
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        try {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          dates.add(data['date'] as String);
        } catch (e) {
          // Skip corrupted entries
        }
      }
    }
    
    if (dates.isEmpty) return null;
    
    // Sort dates and get min/max
    dates.sort();
    
    return {
      'start_date': dates.first,
      'end_date': dates.last,
    };
  }
}
