import 'package:flutter_test/flutter_test.dart';
import 'package:ayuhsolat/services/database_service.dart';
import 'package:ayuhsolat/services/prayer_time_service.dart';

void main() {
  // Initialize Flutter binding for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Weekly Schedule Tests', () {
    test('should be able to get data range from database', () async {
      // First, prefetch some data for TRG01
      final success = await PrayerTimeService.prefetchAndCachePrayerTimes('TRG01');
      expect(success, isTrue, reason: 'Should successfully cache prayer times');

      // Then check if we can get the data range
      final dataRange = await DatabaseService.getDataRange('TRG01');
      expect(dataRange, isNotNull, reason: 'Should have cached data range');
      expect(dataRange!['start_date'], isNotEmpty, reason: 'Should have start date');
      expect(dataRange['end_date'], isNotEmpty, reason: 'Should have end date');
      
      print('Data range: ${dataRange['start_date']} to ${dataRange['end_date']}');
    });

    test('should be able to get prayer times for specific dates', () async {
      // Get today's date in database format
      final now = DateTime.now();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final todayStr = '${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year}';
      
      final prayerTime = await DatabaseService.getPrayerTimeForDate('TRG01', todayStr);
      expect(prayerTime, isNotNull, reason: 'Should find prayer time for today');
      
      if (prayerTime != null) {
        expect(prayerTime.date, equals(todayStr));
        expect(prayerTime.fajr, isNotEmpty, reason: 'Should have Fajr time');
        expect(prayerTime.dhuhr, isNotEmpty, reason: 'Should have Dhuhr time');
        expect(prayerTime.asr, isNotEmpty, reason: 'Should have Asr time');
        expect(prayerTime.maghrib, isNotEmpty, reason: 'Should have Maghrib time');
        expect(prayerTime.isha, isNotEmpty, reason: 'Should have Isha time');
        
        print('Today (${prayerTime.date}): Fajr ${prayerTime.fajr}, Dhuhr ${prayerTime.dhuhr}, Asr ${prayerTime.asr}, Maghrib ${prayerTime.maghrib}, Isha ${prayerTime.isha}');
      }
    });

    test('should be able to get prayer times for next 7 days', () async {
      final now = DateTime.now();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      final weeklyTimes = <String>[];
      
      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
        final prayerTime = await DatabaseService.getPrayerTimeForDate('TRG01', dateStr);
        
        if (prayerTime != null) {
          weeklyTimes.add(dateStr);
        }
      }
      
      expect(weeklyTimes, isNotEmpty, reason: 'Should have prayer times for at least some days this week');
      print('Found prayer times for ${weeklyTimes.length} days in the next week');
      
      for (final dateStr in weeklyTimes) {
        print('- $dateStr');
      }
    });
  });
}
