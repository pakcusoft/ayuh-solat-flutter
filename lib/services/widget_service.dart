import 'dart:io';
import 'package:home_widget/home_widget.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import 'language_service.dart';
import 'prayer_time_service.dart';

class WidgetService {
  static const String _widgetName = 'PrayerTimesWidget';
  static const String _androidWidgetName = 'PrayerTimesWidgetProvider';
  static const String _iOSWidgetName = 'PrayerTimesWidget';

  // Initialize the widget service
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId('group.com.webgeaz.app.ayuhsolat');
  }

  // Update the widget with current prayer times
  static Future<void> updateWidget() async {
    try {
      // Get current zone
      final zone = await PreferencesService.getSelectedZone();
      final lang = await LanguageService.getSelectedLanguage();

      // Get today's prayer times from cache
      final today = DateTime.now();
      final dateStr = _formatDateForDatabase(today);
      final prayerTime = await DatabaseService.getPrayerTimeForDate(
        zone,
        dateStr,
      );

      if (prayerTime != null) {
        // Format times to HH:MM
        final fajr = _formatTime(prayerTime.fajr);
        final syuruk = _formatTime(prayerTime.syuruk);
        final dhuhr = _formatTime(prayerTime.dhuhr);
        final asr = _formatTime(prayerTime.asr);
        final maghrib = _formatTime(prayerTime.maghrib);
        final isha = _formatTime(prayerTime.isha);
        final fajrLabel = _getPrayerLabel('Fajr', lang);
        final syurukLabel = _getPrayerLabel('Syuruk', lang);
        final dhuhrLabel = _getPrayerLabel('Dhuhr', lang);
        final asrLabel = _getPrayerLabel('Asr', lang);
        final maghribLabel = _getPrayerLabel('Maghrib', lang);
        final ishaLabel = _getPrayerLabel('Isha', lang);

        // Save data for the widget
        await HomeWidget.saveWidgetData<String>('fajr', fajr);
        await HomeWidget.saveWidgetData<String>('syuruk', syuruk);
        await HomeWidget.saveWidgetData<String>('dhuhr', dhuhr);
        await HomeWidget.saveWidgetData<String>('asr', asr);
        await HomeWidget.saveWidgetData<String>('maghrib', maghrib);
        await HomeWidget.saveWidgetData<String>('isha', isha);
        await HomeWidget.saveWidgetData<String>('fajr_label', fajrLabel);
        await HomeWidget.saveWidgetData<String>('syuruk_label', syurukLabel);
        await HomeWidget.saveWidgetData<String>('dhuhr_label', dhuhrLabel);
        await HomeWidget.saveWidgetData<String>('asr_label', asrLabel);
        await HomeWidget.saveWidgetData<String>('maghrib_label', maghribLabel);
        await HomeWidget.saveWidgetData<String>('isha_label', ishaLabel);
        await HomeWidget.saveWidgetData<String>('zone', _getZoneName(zone));
        await HomeWidget.saveWidgetData<String>('date', prayerTime.date);
        await HomeWidget.saveWidgetData<String>(
          'day',
          _getShortDay(prayerTime.day),
        );
        await HomeWidget.saveWidgetData<String>('hijri', prayerTime.hijri);
        await HomeWidget.saveWidgetData<String>(
          'lastUpdate',
          DateTime.now().toString(),
        );

        // Find next prayer and current prayer
        final nextPrayer = _findNextPrayer(fajr, dhuhr, asr, maghrib, isha);
        final currentPrayer = _findCurrentPrayer(
          fajr,
          syuruk,
          dhuhr,
          asr,
          maghrib,
          isha,
        );
        await HomeWidget.saveWidgetData<String>(
          'nextPrayer',
          nextPrayer['name'],
        );
        await HomeWidget.saveWidgetData<String>(
          'nextPrayerTime',
          nextPrayer['time'],
        );
        await HomeWidget.saveWidgetData<String>('currentPrayer', currentPrayer);

        // Update the actual widget
        await HomeWidget.updateWidget(
          name: Platform.isAndroid ? _androidWidgetName : _iOSWidgetName,
          androidName: _androidWidgetName,
          iOSName: _iOSWidgetName,
        );

        print('Widget updated successfully');
      } else {
        print('No prayer time data found for widget update');
      }
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  // Find the next prayer based on current time
  static Map<String, String> _findNextPrayer(
    String fajr,
    String dhuhr,
    String asr,
    String maghrib,
    String isha,
  ) {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final prayers = [
      {'name': 'Fajr', 'time': fajr},
      {'name': 'Dhuhr', 'time': dhuhr},
      {'name': 'Asr', 'time': asr},
      {'name': 'Maghrib', 'time': maghrib},
      {'name': 'Isha', 'time': isha},
    ];

    // Find next prayer
    for (final prayer in prayers) {
      if (_compareTime(currentTime, prayer['time']!) < 0) {
        return prayer;
      }
    }

    // If all prayers have passed, next prayer is tomorrow's Fajr
    return {'name': 'Fajr', 'time': fajr};
  }

  // Find the current prayer based on current time
  static String _findCurrentPrayer(
    String fajr,
    String syuruk,
    String dhuhr,
    String asr,
    String maghrib,
    String isha,
  ) {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final prayers = [
      {'name': 'Fajr', 'time': fajr},
      {'name': 'Dhuhr', 'time': dhuhr},
      {'name': 'Asr', 'time': asr},
      {'name': 'Maghrib', 'time': maghrib},
      {'name': 'Isha', 'time': isha},
    ];

    String currentPrayer = '';

    // Find current active prayer (most recent prayer that has passed)
    for (int i = 0; i < prayers.length; i++) {
      final prayerTime = prayers[i]['time']!;
      final prayerName = prayers[i]['name']!;

      // Check if current time is after this prayer time
      if (_compareTime(currentTime, prayerTime) >= 0) {
        currentPrayer = prayerName;

        // Special case for Fajr: if Syuruk has passed, Fajr is no longer current
        if (prayerName == 'Fajr' && _compareTime(currentTime, syuruk) >= 0) {
          currentPrayer = '';
        }
      }
    }

    return currentPrayer;
  }

  // Compare two time strings in HH:MM format
  static int _compareTime(String time1, String time2) {
    final parts1 = time1.split(':');
    final parts2 = time2.split(':');

    final hour1 = int.parse(parts1[0]);
    final minute1 = int.parse(parts1[1]);
    final hour2 = int.parse(parts2[0]);
    final minute2 = int.parse(parts2[1]);

    final totalMinutes1 = hour1 * 60 + minute1;
    final totalMinutes2 = hour2 * 60 + minute2;

    return totalMinutes1.compareTo(totalMinutes2);
  }

  // Format date for database lookup
  static String _formatDateForDatabase(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }

  static String _getPrayerLabel(String prayer, String languageCode) {
    return LanguageService.getLocalizedPrayerName(prayer, languageCode);
  }

  // Format time from HH:MM:SS to HH:MM
  static String _formatTime(String time) {
    if (time == '00:00:00') {
      return '-';
    }

    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  // Get short day name
  static String _getShortDay(String day) {
    const dayMap = {
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
    };
    return dayMap[day] ?? day;
  }

  // Check if widget update is needed
  static Future<bool> isUpdateNeeded() async {
    try {
      final lastUpdate = await HomeWidget.getWidgetData<String>('lastUpdate');
      if (lastUpdate == null) return true;

      final lastUpdateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();

      // Update if it's a new day or more than 1 hour since last update
      final isNewDay = now.day != lastUpdateTime.day;
      final isOverAnHour = now.difference(lastUpdateTime).inHours >= 1;

      return isNewDay || isOverAnHour;
    } catch (e) {
      return true; // Update if there's any error
    }
  }

  // Setup periodic widget updates
  static Future<void> setupPeriodicUpdates() async {
    // This will be called from the main app
    // Updates will be triggered when:
    // 1. App starts
    // 2. Prayer times are refreshed
    // 3. Zone changes
    await updateWidget();
  }

  static String? _getZoneName(String zone) {
    final zones = PrayerTimeService.getZones();
    return zones[zone] ?? zone;
  }
}
