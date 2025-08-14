import 'package:flutter/material.dart';

class AppLocalization {
  final Locale locale;

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization) ??
        AppLocalization(const Locale('ms'));
  }

  // App title
  String get appTitle => 'Ayuh Solat';

  // Settings
  String get settings => locale.languageCode == 'en' ? 'Settings' : 'Tetapan';
  
  // Language
  String get language => locale.languageCode == 'en' ? 'Language' : 'Bahasa';
  String get languageSubtitle => locale.languageCode == 'en' 
      ? 'Choose your preferred language' 
      : 'Pilih bahasa pilihan anda';
  String get english => 'English';
  String get bahasa => 'Bahasa Melayu';
  String languageSaved(String language) => locale.languageCode == 'en' 
      ? 'Language saved: $language' 
      : 'Bahasa disimpan: $language';

  // Notifications
  String get notifications => locale.languageCode == 'en' ? 'Notifications' : 'Pemberitahuan';
  String get notificationsSubtitle => locale.languageCode == 'en'
      ? 'Get reminded 10 minutes before prayer time and when it\'s time to pray.'
      : 'Dapatkan peringatan 10 minit sebelum waktu solat dan ketika tiba masa untuk solat.';
  String get prayerTimeNotifications => locale.languageCode == 'en' 
      ? 'Prayer Time Notifications' 
      : 'Pemberitahuan Waktu Solat';
  String get receiveNotifications => locale.languageCode == 'en' 
      ? 'Receive notifications for prayer times' 
      : 'Terima pemberitahuan untuk waktu solat';
  String get adzanSound => locale.languageCode == 'en' ? 'Adzan Sound' : 'Bunyi Azan';
  String get playAdzanSound => locale.languageCode == 'en' 
      ? 'Play adzan sound when prayer time arrives' 
      : 'Mainkan bunyi azan ketika tiba waktu solat';
  String get notificationsEnabled => locale.languageCode == 'en' 
      ? 'Notifications enabled' 
      : 'Pemberitahuan diaktifkan';
  String get notificationsDisabled => locale.languageCode == 'en' 
      ? 'Notifications disabled' 
      : 'Pemberitahuan dimatikan';
  String get adzanEnabled => locale.languageCode == 'en' 
      ? 'Adzan sound enabled' 
      : 'Bunyi azan diaktifkan';
  String get adzanDisabled => locale.languageCode == 'en' 
      ? 'Adzan sound disabled' 
      : 'Bunyi azan dimatikan';

  // Prayer Zone
  String get prayerTimeZone => locale.languageCode == 'en' ? 'Prayer Time Zone' : 'Zon Waktu Solat';
  String get selectZone => locale.languageCode == 'en' ? 'Select Zone' : 'Pilih Zon';
  String get selectLocation => locale.languageCode == 'en' 
      ? 'Select your location to get accurate prayer times' 
      : 'Pilih lokasi anda untuk mendapat waktu solat yang tepat';
  String zoneSaved(String zone) => locale.languageCode == 'en' 
      ? 'Zone saved: $zone' 
      : 'Zon disimpan: $zone';
  String get currentZone => locale.languageCode == 'en' ? 'Current Zone' : 'Zon Semasa';

  // Prayer Schedule
  String get prayerSchedule => locale.languageCode == 'en' ? 'Prayer Schedule' : 'Jadual Solat';
  String get viewWeeklySchedule => locale.languageCode == 'en'
      ? 'View prayer times for the upcoming week.'
      : 'Lihat waktu solat untuk minggu akan datang.';
  String get viewWeeklyScheduleButton => locale.languageCode == 'en' 
      ? 'View Weekly Schedule' 
      : 'Lihat Jadual Mingguan';
  
  // Testing
  String get notificationTesting => locale.languageCode == 'en' 
      ? 'Notification Testing' 
      : 'Ujian Pemberitahuan';

  // About
  String get about => locale.languageCode == 'en' ? 'About' : 'Mengenai';
  String get aboutText => locale.languageCode == 'en'
      ? 'Prayer times are provided by JAKIM (Jabatan Kemajuan Islam Malaysia) e-Solat API.'
      : 'Waktu solat disediakan oleh API e-Solat JAKIM (Jabatan Kemajuan Islam Malaysia).';
  String get dataUpdated => locale.languageCode == 'en' 
      ? 'Data is updated in real-time.' 
      : 'Data dikemaskini secara masa nyata.';

  // Prayer names
  String get fajr => locale.languageCode == 'en' ? 'Fajr' : 'Subuh';
  String get dhuhr => locale.languageCode == 'en' ? 'Dhuhr' : 'Zohor';
  String get asr => locale.languageCode == 'en' ? 'Asr' : 'Asar';
  String get maghrib => locale.languageCode == 'en' ? 'Maghrib' : 'Maghrib';
  String get isha => locale.languageCode == 'en' ? 'Isha' : 'Isyak';

  // Common
  String get today => locale.languageCode == 'en' ? 'Today' : 'Hari Ini';
  String get loading => locale.languageCode == 'en' ? 'Loading...' : 'Memuatkan...';
  String get refresh => locale.languageCode == 'en' ? 'Refresh' : 'Muat Semula';
  String get nextPrayer => locale.languageCode == 'en' ? 'Next Prayer' : 'Solat Seterusnya';
  String get timeRemaining => locale.languageCode == 'en' ? 'Time Remaining' : 'Masa Berbaki';
  String get currentPrayer => locale.languageCode == 'en' ? 'Current Prayer' : 'Solat Semasa';

  // Notification messages
  String get prayerReminder => locale.languageCode == 'en' ? 'Prayer Reminder' : 'Peringatan Solat';
  String prayerReminderBody(String prayer) => locale.languageCode == 'en'
      ? 'Time for $prayer prayer in 10 minutes'
      : 'Masa untuk solat $prayer dalam 10 minit';
  String get prayerTime => locale.languageCode == 'en' ? 'Prayer Time' : 'Waktu Solat';
  String prayerTimeBody(String prayer) => locale.languageCode == 'en'
      ? 'It\'s time for $prayer prayer'
      : 'Sudah tiba masa untuk solat $prayer';

  // Error messages
  String get errorLoadingPrayerTimes => locale.languageCode == 'en' 
      ? 'Failed to load prayer times' 
      : 'Gagal memuatkan waktu solat';
  String errorLoadingPreferences(String error) => locale.languageCode == 'en'
      ? 'Error loading preferences: $error'
      : 'Ralat memuatkan tetapan: $error';
  String error(String error) => locale.languageCode == 'en'
      ? 'Error: $error'
      : 'Ralat: $error';

  // Time formatting
  String lastUpdated(String time) => locale.languageCode == 'en'
      ? 'Last updated: $time'
      : 'Kemaskini terakhir: $time';

  // Test notifications
  String get testNotification => locale.languageCode == 'en' 
      ? 'Test Notification' 
      : 'Pemberitahuan Ujian';
  String testNotificationBody(String time) => locale.languageCode == 'en'
      ? 'This is a test notification scheduled at $time'
      : 'Ini adalah pemberitahuan ujian dijadualkan pada $time';

  static const List<Locale> supportedLocales = [
    Locale('ms'),
    Locale('en'),
  ];
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalization.supportedLocales.map((l) => l.languageCode).contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    return AppLocalization(locale);
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
