// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ayuh Solat';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose your preferred language';

  @override
  String get english => 'English';

  @override
  String get bahasa => 'Bahasa Melayu';

  @override
  String languageSaved(String language) {
    return 'Language saved: $language';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Get reminded 10 minutes before prayer time and when it\'s time to pray.';

  @override
  String get prayerTimeNotifications => 'Prayer Time Notifications';

  @override
  String get receiveNotifications => 'Receive notifications for prayer times';

  @override
  String get adzanSound => 'Adzan Sound';

  @override
  String get playAdzanSound => 'Play adzan sound when prayer time arrives';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get adzanEnabled => 'Adzan sound enabled';

  @override
  String get adzanDisabled => 'Adzan sound disabled';

  @override
  String get prayerTimeZone => 'Prayer Time Zone';

  @override
  String get selectZone => 'Select Zone';

  @override
  String get selectLocation =>
      'Select your location to get accurate prayer times';

  @override
  String zoneSaved(String zone) {
    return 'Zone saved: $zone';
  }

  @override
  String get currentZone => 'Current Zone';

  @override
  String get prayerSchedule => 'Prayer Schedule';

  @override
  String get viewWeeklySchedule => 'View prayer times for the upcoming week.';

  @override
  String get viewWeeklyScheduleButton => 'View Weekly Schedule';

  @override
  String get notificationTesting => 'Notification Testing';

  @override
  String get about => 'About';

  @override
  String get aboutText =>
      'Prayer times are provided by JAKIM (Jabatan Kemajuan Islam Malaysia) e-Solat API.';

  @override
  String get dataUpdated => 'Data is updated in real-time.';

  @override
  String get fajr => 'Fajr';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get today => 'Today';

  @override
  String get loading => 'Loading...';

  @override
  String get errorLoadingPrayerTimes => 'Failed to load prayer times';

  @override
  String errorLoadingPreferences(String error) {
    return 'Error loading preferences: $error';
  }

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String lastUpdated(String time) {
    return 'Last updated: $time';
  }

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get timeRemaining => 'Time Remaining';

  @override
  String get currentPrayer => 'Current Prayer';

  @override
  String get prayerReminder => 'Prayer Reminder';

  @override
  String prayerReminderBody(String prayer) {
    return 'Time for $prayer prayer in 10 minutes';
  }

  @override
  String get prayerTime => 'Prayer Time';

  @override
  String prayerTimeBody(String prayer) {
    return 'It\'s time for $prayer prayer';
  }

  @override
  String get testNotification => 'Test Notification';

  @override
  String testNotificationBody(String time) {
    return 'This is a test notification scheduled at $time';
  }
}
