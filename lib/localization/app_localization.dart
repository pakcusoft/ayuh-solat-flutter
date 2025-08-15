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
  
  // Testing screen entries
  String get testNotificationDescription => locale.languageCode == 'en'
      ? 'Test various notification functions to ensure they work properly on your device.'
      : 'Uji pelbagai fungsi pemberitahuan untuk memastikan ia berfungsi dengan baik pada peranti anda.';
  
  String get immediateNotifications => locale.languageCode == 'en'
      ? 'Immediate Notifications'
      : 'Pemberitahuan Segera';
  
  String get scheduledNotifications => locale.languageCode == 'en'
      ? 'Scheduled Notifications'
      : 'Pemberitahuan Terjadual';
  
  String get recurringNotifications => locale.languageCode == 'en'
      ? 'Recurring Notifications'
      : 'Pemberitahuan Berulang';
  
  String get systemDiagnostics => locale.languageCode == 'en'
      ? 'System Diagnostics'
      : 'Diagnostik Sistem';
  
  String get testingTips => locale.languageCode == 'en'
      ? 'Testing Tips'
      : 'Tips Ujian';
  
  // Test button labels
  String get testBasicNotification => locale.languageCode == 'en'
      ? 'Test Basic Notification'
      : 'Uji Pemberitahuan Asas';
  
  String get testPrayerReminder => locale.languageCode == 'en'
      ? 'Test Prayer Reminder'
      : 'Uji Peringatan Solat';
  
  String get testPrayerTime => locale.languageCode == 'en'
      ? 'Test Prayer Time'
      : 'Uji Waktu Solat';
  
  String get test1MinuteSchedule => locale.languageCode == 'en'
      ? 'Test 1-Minute Schedule'
      : 'Uji Jadual 1 Minit';
  
  String get every2Minutes10x => locale.languageCode == 'en'
      ? '🔄 Every 2 Minutes (10x)'
      : '🔄 Setiap 2 Minit (10x)';
  
  String get dailyTest7Days => locale.languageCode == 'en'
      ? '📅 Daily Test (7 days)'
      : '📅 Ujian Harian (7 hari)';
  
  String get cancelAllTests => locale.languageCode == 'en'
      ? '❌ Cancel All Tests'
      : '❌ Batalkan Semua Ujian';
  
  String get checkSystemStatus => locale.languageCode == 'en'
      ? '📋 Check System Status'
      : '📋 Semak Status Sistem';
  
  String get debugScheduledNotifications => locale.languageCode == 'en'
      ? '🔍 Debug Scheduled Notifications'
      : '🔍 Nyahpepijat Pemberitahuan Terjadual';
  
  // Test descriptions and messages
  String get scheduledNotificationDescription => locale.languageCode == 'en'
      ? 'Test scheduled notifications (can close app after scheduling):'
      : 'Uji pemberitahuan terjadual (boleh tutup aplikasi selepas menjadualkan):';
  
  String get recurringNotificationDescription => locale.languageCode == 'en'
      ? 'Test automatic recurring notifications (no user interaction required):'
      : 'Uji pemberitahuan berulang automatik (tiada interaksi pengguna diperlukan):';
  
  // Pending notifications section
  String pendingReminders(int count) => locale.languageCode == 'en'
      ? 'Pending Reminders ($count)'
      : 'Peringatan Tertunda ($count)';
  
  String get noPendingNotifications => locale.languageCode == 'en'
      ? 'No pending notifications scheduled'
      : 'Tiada pemberitahuan tertunda dijadualkan';
  
  String get scheduledNotificationsDescription => locale.languageCode == 'en'
      ? 'Scheduled notifications that will trigger automatically (refreshes every 10s)'
      : 'Pemberitahuan terjadual yang akan dicetuskan secara automatik (menyegar setiap 10s)';
  
  String get noNotificationsScheduled => locale.languageCode == 'en'
      ? 'No notifications scheduled'
      : 'Tiada pemberitahuan dijadualkan';
  
  String andMoreNotifications(int count) => locale.languageCode == 'en'
      ? '... and $count more notifications'
      : '... dan $count lagi pemberitahuan';
  
  // Success messages
  String get testNotificationSent => locale.languageCode == 'en'
      ? 'Test notification sent!'
      : 'Pemberitahuan ujian dihantar!';
  
  String get testReminderSent => locale.languageCode == 'en'
      ? 'Test reminder sent!'
      : 'Peringatan ujian dihantar!';
  
  String get testPrayerTimeNotificationSent => locale.languageCode == 'en'
      ? 'Test prayer time notification!'
      : 'Pemberitahuan waktu solat ujian!';
  
  String get testNotificationScheduled1Min => locale.languageCode == 'en'
      ? 'Test notification scheduled for 1 minute! You can close the app to test.'
      : 'Pemberitahuan ujian dijadualkan untuk 1 minit! Anda boleh tutup aplikasi untuk menguji.';
  
  String get recurringTestStarted => locale.languageCode == 'en'
      ? '🔄 Recurring test started! 10 notifications every 2 minutes. NO user interaction needed!'
      : '🔄 Ujian berulang dimulakan! 10 pemberitahuan setiap 2 minit. TIADA interaksi pengguna diperlukan!';
  
  String get dailyRecurringTestStarted => locale.languageCode == 'en'
      ? '📅 Daily recurring test started! 1 notification per day for 7 days. Completely automatic!'
      : '📅 Ujian berulang harian dimulakan! 1 pemberitahuan setiap hari selama 7 hari. Sepenuhnya automatik!';
  
  String get allTestNotificationsCancelled => locale.languageCode == 'en'
      ? '❌ All test notifications cancelled successfully.'
      : '❌ Semua pemberitahuan ujian dibatalkan dengan berjaya.';
  
  String get systemStatusLogged => locale.languageCode == 'en'
      ? '📋 System status logged to console. Check logs for details.'
      : '📋 Status sistem dilog ke konsol. Semak log untuk butiran.';
  
  String get scheduledNotificationsDebugLogged => locale.languageCode == 'en'
      ? '🔍 Scheduled notifications debug info logged to console.'
      : '🔍 Maklumat nyahpepijat pemberitahuan terjadual dilog ke konsol.';
  
  // Testing tips content
  String get testingTipsContent => locale.languageCode == 'en'
      ? '• For scheduled notifications, you can close the app after scheduling to test background functionality.\n'
        '• Check your device\'s notification settings if notifications don\'t appear.\n'
        '• Recurring notifications are fully automatic and don\'t require user interaction.\n'
        '• Use "Cancel All Tests" to stop recurring notification tests.\n'
        '• Check the debug console/logs for detailed information about notification status.'
      : '• Untuk pemberitahuan terjadual, anda boleh tutup aplikasi selepas menjadualkan untuk menguji fungsi latar belakang.\n'
        '• Semak tetapan pemberitahuan peranti anda jika pemberitahuan tidak muncul.\n'
        '• Pemberitahuan berulang adalah sepenuhnya automatik dan tidak memerlukan interaksi pengguna.\n'
        '• Gunakan "Batalkan Semua Ujian" untuk menghentikan ujian pemberitahuan berulang.\n'
        '• Semak konsol/log nyahpepijat untuk maklumat terperinci tentang status pemberitahuan.';
  
  // Additional missing entries
  String get hijriLabel => locale.languageCode == 'en' ? 'Hijri' : 'Hijrah';
  
  String get qiblaDirection => locale.languageCode == 'en' 
      ? 'Qibla Direction' 
      : 'Arah Kiblat';
  
  String get type => locale.languageCode == 'en' ? 'Type' : 'Jenis';
  
  String get id => locale.languageCode == 'en' ? 'ID' : 'ID';
  
  String get unknown => locale.languageCode == 'en' ? 'Unknown' : 'Tidak Diketahui';
  
  // Day names localization
  String get monday => locale.languageCode == 'en' ? 'Monday' : 'Isnin';
  String get tuesday => locale.languageCode == 'en' ? 'Tuesday' : 'Selasa';
  String get wednesday => locale.languageCode == 'en' ? 'Wednesday' : 'Rabu';
  String get thursday => locale.languageCode == 'en' ? 'Thursday' : 'Khamis';
  String get friday => locale.languageCode == 'en' ? 'Friday' : 'Jumaat';
  String get saturday => locale.languageCode == 'en' ? 'Saturday' : 'Sabtu';
  String get sunday => locale.languageCode == 'en' ? 'Sunday' : 'Ahad';
  
  // Weekly schedule entries
  String get weeklyPrayerSchedule => locale.languageCode == 'en'
      ? 'Weekly Prayer Schedule'
      : 'Jadual Solat Mingguan';
  
  String get cachedDataRange => locale.languageCode == 'en'
      ? 'Cached Data Range'
      : 'Julat Data Tersimpan';
  
  String get nextSevenDays => locale.languageCode == 'en'
      ? 'Next 7 Days Prayer Schedule'
      : 'Jadual Solat 7 Hari Akan Datang';
  
  String get zone => locale.languageCode == 'en' ? 'Zone' : 'Zon';
  String get from => locale.languageCode == 'en' ? 'From' : 'Dari';
  String get to => locale.languageCode == 'en' ? 'To' : 'Hingga';
  
  String get todayHighlightInfo => locale.languageCode == 'en'
      ? 'Today\'s row is highlighted. Data is from cached offline storage.'
      : 'Baris hari ini ditonjolkan. Data adalah dari storan luar talian tersimpan.';
  
  String get noCachedDataWeek => locale.languageCode == 'en'
      ? 'No cached data available for the upcoming week.\nPlease refresh the main prayer times screen to fetch new data.'
      : 'Tiada data tersimpan tersedia untuk minggu akan datang.\nSila muat semula skrin waktu solat utama untuk mendapatkan data baharu.';
  
  String errorLoadingWeekly(String error) => locale.languageCode == 'en'
      ? 'Error loading weekly schedule: $error'
      : 'Ralat memuatkan jadual mingguan: $error';
  
  // Month abbreviations for localization
  String getLocalizedMonth(String monthAbbr) {
    if (locale.languageCode == 'en') return monthAbbr;
    
    const monthMap = {
      'Jan': 'Jan', 'Feb': 'Feb', 'Mar': 'Mac', 'Apr': 'Apr', 'May': 'Mei', 'Jun': 'Jun',
      'Jul': 'Jul', 'Aug': 'Ogs', 'Sep': 'Sep', 'Oct': 'Okt', 'Nov': 'Nov', 'Dec': 'Dis'
    };
    return monthMap[monthAbbr] ?? monthAbbr;
  }
  
  // Helper method to get localized day name
  String getLocalizedDayName(String englishDay) {
    switch (englishDay.toLowerCase()) {
      case 'monday': return monday;
      case 'tuesday': return tuesday;
      case 'wednesday': return wednesday;
      case 'thursday': return thursday;
      case 'friday': return friday;
      case 'saturday': return saturday;
      case 'sunday': return sunday;
      default: return englishDay;
    }
  }
  
  // Method used by weekly schedule screen
  String getDayName(String englishDay) {
    return getLocalizedDayName(englishDay);
  }
  
  // Method to get localized month abbreviation
  String getMonthAbbreviation(String monthAbbr) {
    return getLocalizedMonth(monthAbbr);
  }

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
      
  // Notification titles for specific prayers with times
  String prayerReminderTitle(String prayer) => locale.languageCode == 'en'
      ? '$prayer Prayer Reminder'
      : 'Peringatan Solat $prayer';
      
  String prayerTimeTitle(String prayer) => locale.languageCode == 'en'
      ? '$prayer Prayer Time'
      : 'Waktu Solat $prayer';
      
  String prayerReminderBodyWithTime(String prayer, String time) => locale.languageCode == 'en'
      ? '$prayer prayer in 10 minutes at $time'
      : 'Solat $prayer dalam 10 minit pada $time';
      
  // Method to get localized prayer name by English name
  String getLocalizedPrayerName(String englishPrayerName) {
    switch (englishPrayerName.toLowerCase()) {
      case 'fajr': return fajr;
      case 'dhuhr': return dhuhr;
      case 'asr': return asr;
      case 'maghrib': return maghrib;
      case 'isha': return isha;
      default: return englishPrayerName;
    }
  }
      
  // Status labels
  String get currentPrayer => locale.languageCode == 'en' 
      ? 'CURRENT' 
      : 'SEMASA';
      
  // Error messages for prayer times screen
  String get tryAgain => locale.languageCode == 'en' 
      ? 'Try Again' 
      : 'Cuba Lagi';
  String get noDataAvailable => locale.languageCode == 'en'
      ? 'No data available for this zone'
      : 'Tiada data tersedia untuk zon ini';
  String get noPrayerTimes => locale.languageCode == 'en'
      ? 'No prayer times available'
      : 'Tiada waktu solat tersedia';
  String get pleaseChangeZone => locale.languageCode == 'en'
      ? 'Please change your zone in settings'
      : 'Sila tukar zon anda dalam tetapan';
  String get openSettings => locale.languageCode == 'en'
      ? 'Open Settings'
      : 'Buka Tetapan';
      
  // Prayer name for Syuruk
  String get syuruk => locale.languageCode == 'en' ? 'Syuruk' : 'Syuruk';
  
  // Offline mode
  String get offlineMode => locale.languageCode == 'en'
      ? 'Offline Mode'
      : 'Mod Luar Talian';
      
  // Zone search functionality
  String get searchZones => locale.languageCode == 'en'
      ? 'Search zones...'
      : 'Cari zon...';
      
  String searchResults(int count) => locale.languageCode == 'en'
      ? 'Found $count zones'
      : 'Dijumpai $count zon';
      
  String get noZonesFound => locale.languageCode == 'en'
      ? 'No zones found'
      : 'Tiada zon dijumpai';
      
  String get tryDifferentSearch => locale.languageCode == 'en'
      ? 'Try a different search term'
      : 'Cuba istilah carian yang berbeza';
      
  String get searchByZoneOrLocation => locale.languageCode == 'en'
      ? 'Search by zone code or location name'
      : 'Cari mengikut kod zon atau nama lokasi';

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
  bool shouldReload(AppLocalizationDelegate old) => true;
}
