import 'package:flutter_test/flutter_test.dart';
import 'package:ayuhsolat/services/prayer_time_service.dart';

void main() {
  group('Duration API Tests', () {
    test('fetchPrayerTimesForDuration should return valid data', () async {
      // Test the duration API call
      final response = await PrayerTimeService.fetchPrayerTimesForDuration(
        zone: 'TRG01',
        startDate: '2025-08-09',
        endDate: '2025-08-15', // Just test one week
      );

      expect(response, isNotNull);
      expect(response!.status, equals('OK!'));
      expect(response.prayerTimes, isNotEmpty);
      expect(response.prayerTimes.length, greaterThan(0));
      expect(response.zone, equals('TRG01'));
      expect(response.periodType, equals('duration'));

      // Check the first prayer time entry
      final firstEntry = response.prayerTimes.first;
      expect(firstEntry.date, isNotEmpty);
      expect(firstEntry.fajr, isNotEmpty);
      expect(firstEntry.dhuhr, isNotEmpty);
      expect(firstEntry.asr, isNotEmpty);
      expect(firstEntry.maghrib, isNotEmpty);
      expect(firstEntry.isha, isNotEmpty);
      
      print('Successfully fetched ${response.prayerTimes.length} prayer times');
      print('First entry: ${firstEntry.date} - Fajr: ${firstEntry.fajr}');
    });

    test('fetchPrayerTimesForDuration should handle invalid zone', () async {
      final response = await PrayerTimeService.fetchPrayerTimesForDuration(
        zone: 'INVALID',
        startDate: '2025-08-09',
        endDate: '2025-08-15',
      );

      // The API might return null or empty data for invalid zones
      if (response != null) {
        expect(response.prayerTimes, isEmpty);
      }
    });

    test('regular single day API should also work', () async {
      final response = await PrayerTimeService.fetchPrayerTimes(
        zone: 'TRG01',
        period: 'today',
      );

      expect(response, isNotNull);
      expect(response!.status, anyOf(['OK!', contains('Cached')]));
      expect(response.prayerTimes, isNotEmpty);
      expect(response.prayerTimes.length, equals(1));
      
      print('Single day API also working: ${response.prayerTimes.first.date}');
    });
  });
}
