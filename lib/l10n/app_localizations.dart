import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ayuh Solat'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bahasa.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get bahasa;

  /// No description provided for @languageSaved.
  ///
  /// In en, this message translates to:
  /// **'Language saved: {language}'**
  String languageSaved(String language);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded 10 minutes before prayer time and when it\'s time to pray.'**
  String get notificationsSubtitle;

  /// No description provided for @prayerTimeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Prayer Time Notifications'**
  String get prayerTimeNotifications;

  /// No description provided for @receiveNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for prayer times'**
  String get receiveNotifications;

  /// No description provided for @adzanSound.
  ///
  /// In en, this message translates to:
  /// **'Adzan Sound'**
  String get adzanSound;

  /// No description provided for @playAdzanSound.
  ///
  /// In en, this message translates to:
  /// **'Play adzan sound when prayer time arrives'**
  String get playAdzanSound;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @adzanEnabled.
  ///
  /// In en, this message translates to:
  /// **'Adzan sound enabled'**
  String get adzanEnabled;

  /// No description provided for @adzanDisabled.
  ///
  /// In en, this message translates to:
  /// **'Adzan sound disabled'**
  String get adzanDisabled;

  /// No description provided for @prayerTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Prayer Time Zone'**
  String get prayerTimeZone;

  /// No description provided for @selectZone.
  ///
  /// In en, this message translates to:
  /// **'Select Zone'**
  String get selectZone;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select your location to get accurate prayer times'**
  String get selectLocation;

  /// No description provided for @zoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Zone saved: {zone}'**
  String zoneSaved(String zone);

  /// No description provided for @currentZone.
  ///
  /// In en, this message translates to:
  /// **'Current Zone'**
  String get currentZone;

  /// No description provided for @prayerSchedule.
  ///
  /// In en, this message translates to:
  /// **'Prayer Schedule'**
  String get prayerSchedule;

  /// No description provided for @viewWeeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'View prayer times for the upcoming week.'**
  String get viewWeeklySchedule;

  /// No description provided for @viewWeeklyScheduleButton.
  ///
  /// In en, this message translates to:
  /// **'View Weekly Schedule'**
  String get viewWeeklyScheduleButton;

  /// No description provided for @notificationTesting.
  ///
  /// In en, this message translates to:
  /// **'Notification Testing'**
  String get notificationTesting;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are provided by JAKIM (Jabatan Kemajuan Islam Malaysia) e-Solat API.'**
  String get aboutText;

  /// No description provided for @dataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Data is updated in real-time.'**
  String get dataUpdated;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorLoadingPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load prayer times'**
  String get errorLoadingPrayerTimes;

  /// No description provided for @errorLoadingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Error loading preferences: {error}'**
  String errorLoadingPreferences(String error);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String lastUpdated(String time);

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemaining;

  /// No description provided for @currentPrayer.
  ///
  /// In en, this message translates to:
  /// **'Current Prayer'**
  String get currentPrayer;

  /// No description provided for @prayerReminder.
  ///
  /// In en, this message translates to:
  /// **'Prayer Reminder'**
  String get prayerReminder;

  /// No description provided for @prayerReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time for {prayer} prayer in 10 minutes'**
  String prayerReminderBody(String prayer);

  /// No description provided for @prayerTime.
  ///
  /// In en, this message translates to:
  /// **'Prayer Time'**
  String get prayerTime;

  /// No description provided for @prayerTimeBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {prayer} prayer'**
  String prayerTimeBody(String prayer);

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'This is a test notification scheduled at {time}'**
  String testNotificationBody(String time);

  /// No description provided for @syuruk.
  ///
  /// In en, this message translates to:
  /// **'Syuruk'**
  String get syuruk;

  /// No description provided for @prayerDetail.
  ///
  /// In en, this message translates to:
  /// **'Prayer Detail'**
  String get prayerDetail;

  /// No description provided for @timeRemainingUntil.
  ///
  /// In en, this message translates to:
  /// **'Time remaining until {prayer}'**
  String timeRemainingUntil(String prayer);

  /// No description provided for @prayerIsOngoing.
  ///
  /// In en, this message translates to:
  /// **'{prayer} is ongoing'**
  String prayerIsOngoing(String prayer);

  /// No description provided for @nextPrayerIn.
  ///
  /// In en, this message translates to:
  /// **'Next: {prayer} in {time}'**
  String nextPrayerIn(String prayer, String time);

  /// No description provided for @prayerTimeHasEnded.
  ///
  /// In en, this message translates to:
  /// **'{prayer} prayer time has ended'**
  String prayerTimeHasEnded(String prayer);

  /// No description provided for @nextPrayerHasStarted.
  ///
  /// In en, this message translates to:
  /// **'Next prayer has started'**
  String get nextPrayerHasStarted;

  /// No description provided for @prayerCompleted.
  ///
  /// In en, this message translates to:
  /// **'Prayer completed'**
  String get prayerCompleted;

  /// No description provided for @dateInformation.
  ///
  /// In en, this message translates to:
  /// **'Date Information'**
  String get dateInformation;

  /// No description provided for @gregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get gregorian;

  /// No description provided for @hijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri'**
  String get hijri;

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'Current Time'**
  String get currentTime;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'ENDED'**
  String get ended;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get upcoming;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
