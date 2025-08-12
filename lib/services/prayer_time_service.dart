import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/prayer_time.dart';
import 'database_service.dart';
import 'widget_service.dart';
import 'notification_service.dart';

class PrayerTimeService {
  static const String _baseUrl = 'https://www.e-solat.gov.my/index.php';
  
  // Main method to get prayer times with caching fallback
  static Future<PrayerTimeResponse?> fetchPrayerTimes({
    String period = 'today',
    String zone = 'WLY01',
  }) async {
    try {
      // Try to fetch from API first
      final uri = Uri.parse('$_baseUrl?r=esolatApi/takwimsolat&period=$period&zone=$zone');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException("5 seconds timeout");
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return PrayerTimeResponse.fromJson(jsonData);
      } else {
        print('API returned status code: ${response.statusCode}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching from API: $e');
      
      // Fallback to cached data
      print('Falling back to cached data...');
      final cachedData = await DatabaseService.getTodaysPrayerTime(zone);
      if (cachedData != null) {
        print('Using cached prayer times for $zone');
        return cachedData;
      }

      print('No cached data available for $zone');
      return null;
    }
  }

  // Fetch prayer times for a date range using POST with form data
  static Future<PrayerTimeResponse?> fetchPrayerTimesForDuration({
    required String zone,
    required String startDate, // yyyy-mm-dd format
    required String endDate,   // yyyy-mm-dd format
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl?r=esolatApi/takwimsolat&period=duration&zone=$zone');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'datestart': startDate,
          'dateend': endDate,
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return PrayerTimeResponse.fromJson(jsonData);
      } else {
        print('Failed to fetch duration data. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching duration prayer times: $e');
      return null;
    }
  }
  
  // Pre-fetch and cache prayer times for the next month
  static Future<bool> prefetchAndCachePrayerTimes(String zone) async {
    try {
      final now = DateTime.now();
      final startDate = now;
      final endDate = DateTime(now.year, now.month + 2, 0); // End of next month
      
      final startDateStr = _formatDateForAPI(startDate);
      final endDateStr = _formatDateForAPI(endDate);
      
      print('Prefetching prayer times for $zone from $startDateStr to $endDateStr');
      
      final response = await fetchPrayerTimesForDuration(
        zone: zone,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      if (response != null && response.prayerTimes.isNotEmpty) {
        // Save to database
        await DatabaseService.savePrayerTimes(
          zone,
          response.prayerTimes,
          response.bearing,
          response.serverTime,
        );
        
        // Update metadata
        await DatabaseService.updateCacheMetadata(
          zone: zone,
          lastUpdated: DateTime.now(),
          nextUpdate: DateTime.now().add(const Duration(days: 7)), // Update weekly
          dataStartDate: startDateStr,
          dataEndDate: endDateStr,
        );
        
        print('Successfully cached ${response.prayerTimes.length} prayer times for $zone');
        
        // Update widget after caching new data
        WidgetService.updateWidget();
        
        // Schedule notifications for the cached prayer times
        await scheduleNotificationsForCachedData(response.prayerTimes);
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error prefetching prayer times: $e');
      return false;
    }
  }
  
  // Check and update cache if needed
  static Future<void> checkAndUpdateCache(String zone) async {
    try {
      final needsUpdate = await DatabaseService.needsCacheUpdate(zone);
      if (needsUpdate) {
        print('Cache needs update for $zone');
        await prefetchAndCachePrayerTimes(zone);
        
        // Clean old data
        await DatabaseService.cleanOldData();
      } else {
        print('Cache is still fresh for $zone');
        
        // Even if cache is fresh, we still need to schedule notifications for current cached data
        await scheduleNotificationsForCurrentCache(zone);
      }
    } catch (e) {
      print('Error checking cache: $e');
    }
  }
  
  // Schedule notifications for cached prayer times (limited to next 3 days)
  static Future<void> scheduleNotificationsForCachedData(List<PrayerTime> prayerTimes) async {
    try {
      // Filter prayer times to only include the next 3 days
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final threeDaysFromNow = today.add(const Duration(days: 3));
      final dateFormat = DateFormat('dd-MMM-yyyy');
      
      final filteredPrayerTimes = prayerTimes.where((prayerTime) {
        try {
          final prayerDate = dateFormat.parse(prayerTime.date);
          return prayerDate.isAtSameMomentAs(today) || 
                 (prayerDate.isAfter(today) && prayerDate.isBefore(threeDaysFromNow.add(const Duration(days: 1))));
        } catch (e) {
          print('Error parsing prayer time date ${prayerTime.date}: $e');
          return false;
        }
      }).toList();
      
      print('Found ${prayerTimes.length} total prayer times, filtered to ${filteredPrayerTimes.length} for next 3 days, setting up bulk notifications');
      await NotificationService.scheduleBulkNotificationsForPrayerTimes(filteredPrayerTimes);
      print('Successfully set up bulk notifications (3 days scope)');
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }
  
  // Schedule notifications for current cached data (limited to next 3 days)
  static Future<void> scheduleNotificationsForCurrentCache(String zone) async {
    try {
      // Get cached prayer times for only the next 3 days instead of entire month
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final threeDaysFromNow = today.add(const Duration(days: 3));
      
      final cachedData = await DatabaseService.getPrayerTimesForDateRange(
        zone,
        today,
        threeDaysFromNow,
      );
      
      if (cachedData.isNotEmpty) {
        print('Found ${cachedData.length} cached prayer times for next 3 days, setting up bulk notifications');
        await NotificationService.scheduleBulkNotificationsForPrayerTimes(cachedData);
        print('Successfully set up bulk notifications from cache (3 days scope)');
      } else {
        print('No cached data available for notifications (3 days scope)');
      }
    } catch (e) {
      print('Error scheduling notifications from cache: $e');
    }
  }
  
  // Helper method to format date for API (yyyy-mm-dd)
  static String _formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // Helper method to get available zones (official JAKIM e-Solat zones)
  static Map<String, String> getZones() {
    return {
      // Johor
      'JHR01': 'Pulau Aur dan Pulau Pemanggil',
      'JHR02': 'Johor Bahru, Kota Tinggi, Mersing, Kulai',
      'JHR03': 'Kluang, Pontian',
      'JHR04': 'Batu Pahat, Muar, Segamat, Gemas Johor, Tangkak',
      
      // Kedah
      'KDH01': 'Kota Setar, Kubang Pasu, Pokok Sena (Daerah Kecil)',
      'KDH02': 'Kuala Muda, Yan, Pendang',
      'KDH03': 'Padang Terap, Sik',
      'KDH04': 'Baling',
      'KDH05': 'Bandar Baharu, Kulim',
      'KDH06': 'Langkawi',
      'KDH07': 'Puncak Gunung Jerai',
      
      // Kelantan
      'KTN01': 'Bachok, Kota Bharu, Machang, Pasir Mas, Pasir Puteh, Tanah Merah, Tumpat, Kuala Krai, Mukim Chiku',
      'KTN02': 'Gua Musang (Daerah Galas Dan Bertam), Jeli, Jajahan Kecil Lojing',
      
      // Melaka
      'MLK01': 'SELURUH NEGERI MELAKA',
      
      // Negeri Sembilan
      'NGS01': 'Tampin, Jempol',
      'NGS02': 'Jelebu, Kuala Pilah, Rembau',
      'NGS03': 'Port Dickson, Seremban',
      
      // Pahang
      'PHG01': 'Pulau Tioman',
      'PHG02': 'Kuantan, Pekan, Muadzam Shah',
      'PHG03': 'Jerantut, Temerloh, Maran, Bera, Chenor, Jengka',
      'PHG04': 'Bentong, Lipis, Raub',
      'PHG05': 'Genting Sempah, Janda Baik, Bukit Tinggi',
      'PHG06': 'Cameron Highlands, Genting Higlands, Bukit Fraser',
      'PHG07': 'Zon Khas Daerah Rompin, (Mukim Rompin, Mukim Endau, Mukim Pontian)',
      
      // Perlis
      'PLS01': 'Kangar, Padang Besar, Arau',
      
      // Pulau Pinang
      'PNG01': 'Seluruh Negeri Pulau Pinang',
      
      // Perak
      'PRK01': 'Tapah, Slim River, Tanjung Malim',
      'PRK02': 'Kuala Kangsar, Sg. Siput , Ipoh, Batu Gajah, Kampar',
      'PRK03': 'Lenggong, Pengkalan Hulu, Grik',
      'PRK04': 'Temengor, Belum',
      'PRK05': 'Kg Gajah, Teluk Intan, Bagan Datuk, Seri Iskandar, Beruas, Parit, Lumut, Sitiawan, Pulau Pangkor',
      'PRK06': 'Selama, Taiping, Bagan Serai, Parit Buntar',
      'PRK07': 'Bukit Larut',
      
      // Sabah
      'SBH01': 'Bahagian Sandakan (Timur), Bukit Garam, Semawang, Temanggong, Tambisan, Bandar Sandakan, Sukau',
      'SBH02': 'Beluran, Telupid, Pinangah, Terusan, Kuamut, Bahagian Sandakan (Barat)',
      'SBH03': 'Lahad Datu, Silabukan, Kunak, Sahabat, Semporna, Tungku, Bahagian Tawau  (Timur)',
      'SBH04': 'Bandar Tawau, Balong, Merotai, Kalabakan, Bahagian Tawau (Barat)',
      'SBH05': 'Kudat, Kota Marudu, Pitas, Pulau Banggi, Bahagian Kudat',
      'SBH06': 'Gunung Kinabalu',
      'SBH07': 'Kota Kinabalu, Ranau, Kota Belud, Tuaran, Penampang, Papar, Putatan, Bahagian Pantai Barat',
      'SBH08': 'Pensiangan, Keningau, Tambunan, Nabawan, Bahagian Pendalaman (Atas)',
      'SBH09': 'Beaufort, Kuala Penyu, Sipitang, Tenom, Long Pasia, Membakut, Weston, Bahagian Pendalaman (Bawah)',
      
      // Selangor
      'SGR01': 'Gombak, Petaling, Sepang, Hulu Langat, Hulu Selangor, S.Alam',
      'SGR02': 'Kuala Selangor, Sabak Bernam',
      'SGR03': 'Klang, Kuala Langat',
      
      // Sarawak
      'SWK01': 'Limbang, Lawas, Sundar, Trusan',
      'SWK02': 'Miri, Niah, Bekenu, Sibuti, Marudi',
      'SWK03': 'Pandan, Belaga, Suai, Tatau, Sebauh, Bintulu',
      'SWK04': 'Sibu, Mukah, Dalat, Song, Igan, Oya, Balingian, Kanowit, Kapit',
      'SWK05': 'Sarikei, Matu, Julau, Rajang, Daro, Bintangor, Belawai',
      'SWK06': 'Lubok Antu, Sri Aman, Roban, Debak, Kabong, Lingga, Engkelili, Betong, Spaoh, Pusa, Saratok',
      'SWK07': 'Serian, Simunjan, Samarahan, Sebuyau, Meludam',
      'SWK08': 'Kuching, Bau, Lundu, Sematan',
      'SWK09': 'Zon Khas (Kampung Patarikan)',
      
      // Terengganu
      'TRG01': 'Kuala Terengganu, Marang, Kuala Nerus',
      'TRG02': 'Besut, Setiu',
      'TRG03': 'Hulu Terengganu',
      'TRG04': 'Dungun, Kemaman',
      
      // Wilayah Persekutuan
      'WLY01': 'Kuala Lumpur, Putrajaya',
      'WLY02': 'Labuan',
    };
  }
}
