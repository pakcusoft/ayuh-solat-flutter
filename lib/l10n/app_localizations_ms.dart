// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Ayuh Solat';

  @override
  String get settings => 'Tetapan';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSubtitle => 'Pilih bahasa pilihan anda';

  @override
  String get english => 'English';

  @override
  String get bahasa => 'Bahasa Melayu';

  @override
  String languageSaved(String language) {
    return 'Bahasa disimpan: $language';
  }

  @override
  String get notifications => 'Pemberitahuan';

  @override
  String get notificationsSubtitle =>
      'Dapatkan peringatan 10 minit sebelum waktu solat dan ketika tiba masa untuk solat.';

  @override
  String get prayerTimeNotifications => 'Pemberitahuan Waktu Solat';

  @override
  String get receiveNotifications => 'Terima pemberitahuan untuk waktu solat';

  @override
  String get adzanSound => 'Bunyi Azan';

  @override
  String get playAdzanSound => 'Mainkan bunyi azan ketika tiba waktu solat';

  @override
  String get notificationsEnabled => 'Pemberitahuan diaktifkan';

  @override
  String get notificationsDisabled => 'Pemberitahuan dimatikan';

  @override
  String get adzanEnabled => 'Bunyi azan diaktifkan';

  @override
  String get adzanDisabled => 'Bunyi azan dimatikan';

  @override
  String get prayerTimeZone => 'Zon Waktu Solat';

  @override
  String get selectZone => 'Pilih Zon';

  @override
  String get selectLocation =>
      'Pilih lokasi anda untuk mendapat waktu solat yang tepat';

  @override
  String zoneSaved(String zone) {
    return 'Zon disimpan: $zone';
  }

  @override
  String get currentZone => 'Zon Semasa';

  @override
  String get prayerSchedule => 'Jadual Solat';

  @override
  String get viewWeeklySchedule =>
      'Lihat waktu solat untuk minggu akan datang.';

  @override
  String get viewWeeklyScheduleButton => 'Lihat Jadual Mingguan';

  @override
  String get notificationTesting => 'Ujian Pemberitahuan';

  @override
  String get about => 'Mengenai';

  @override
  String get aboutText =>
      'Waktu solat disediakan oleh API e-Solat JAKIM (Jabatan Kemajuan Islam Malaysia).';

  @override
  String get dataUpdated => 'Data dikemaskini secara masa nyata.';

  @override
  String get fajr => 'Subuh';

  @override
  String get dhuhr => 'Zohor';

  @override
  String get asr => 'Asar';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isyak';

  @override
  String get today => 'Hari Ini';

  @override
  String get loading => 'Memuatkan...';

  @override
  String get errorLoadingPrayerTimes => 'Gagal memuatkan waktu solat';

  @override
  String errorLoadingPreferences(String error) {
    return 'Ralat memuatkan tetapan: $error';
  }

  @override
  String error(String error) {
    return 'Ralat: $error';
  }

  @override
  String get refresh => 'Muat Semula';

  @override
  String lastUpdated(String time) {
    return 'Kemaskini terakhir: $time';
  }

  @override
  String get nextPrayer => 'Solat Seterusnya';

  @override
  String get timeRemaining => 'Masa Berbaki';

  @override
  String get currentPrayer => 'Solat Semasa';

  @override
  String get prayerReminder => 'Peringatan Solat';

  @override
  String prayerReminderBody(String prayer) {
    return 'Masa untuk solat $prayer dalam 10 minit';
  }

  @override
  String get prayerTime => 'Waktu Solat';

  @override
  String prayerTimeBody(String prayer) {
    return 'Sudah tiba masa untuk solat $prayer';
  }

  @override
  String get testNotification => 'Pemberitahuan Ujian';

  @override
  String testNotificationBody(String time) {
    return 'Ini adalah pemberitahuan ujian dijadualkan pada $time';
  }
}
