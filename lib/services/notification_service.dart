import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/prayer_time.dart';
import 'preferences_service.dart';
import 'database_service.dart';

/// NotificationService handles prayer time notifications using scheduled system notifications.
///
/// This service has been refactored to use flutter_local_notifications' zonedSchedule() method
/// instead of Timer.periodic, making notifications work reliably even when the app is closed
/// or running in the background.
///
/// Key features:
/// - Schedules exact notifications using system alarm managers
/// - Works when app is closed/killed or in background
/// - Uses AndroidScheduleMode.exactAllowWhileIdle for reliable delivery
/// - Automatically plays adzan when prayer time notifications are tapped
/// - Provides debugging methods to inspect scheduled notifications
class NotificationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Flutter local notifications
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // For in-app notifications
  static final List<Map<String, dynamic>> _recentNotifications = [];
  static StreamController<Map<String, dynamic>>? _notificationController;

  // Notification ID counters
  static int _reminderNotificationId = 1000;
  static int _prayerNotificationId = 2000;

  // Getters for UI access
  static List<Map<String, dynamic>> get recentNotifications =>
      _recentNotifications;
  static Stream<Map<String, dynamic>>? get notificationStream =>
      _notificationController?.stream;

  static Future<void> initialize() async {
    if (kDebugMode) {
      print('NotificationService initialized');
    }

    // Initialize timezone
    tz.initializeTimeZones();

    // Set timezone to Malaysia Time (UTC+8)
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    if (kDebugMode) {
      print('Timezone set to Malaysia Time (UTC+8): ${tz.local}');
      print('Current local time: ${tz.TZDateTime.now(tz.local)}');
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request notification permissions
    await _requestNotificationPermissions();
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Unified notification response handler for both foreground and background notifications
  @pragma('vm:entry-point')
  static Future<void> _onNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    try {
      if (kDebugMode) {
        print('📱 Notification response received:');
        print('   Payload: ${notificationResponse.payload}');
        print('   Action ID: ${notificationResponse.actionId}');
        print('   Input: ${notificationResponse.input}');
        print(
          '   Notification response type: ${notificationResponse.notificationResponseType}',
        );
      }

      final payload = notificationResponse.payload;
      if (payload == null) {
        if (kDebugMode) {
          print('⚠️ Notification payload is null');
        }
        return;
      }

      // Handle prayer time notifications by playing adzan
      if (payload.startsWith('prayer_time_') ||
          payload.startsWith('chain_prayer_time_')) {
        if (kDebugMode) {
          print('🕌 Playing adzan for prayer time notification');
        }
        await _playAdzan();
      }

      // Handle chained notifications - schedule the next one
      if (payload.startsWith('chain_')) {
        if (payload.startsWith('chain_test_')) {
          // Handle test chain
          if (kDebugMode) {
            print('🔗 Handling test chain notification');
          }
          await _scheduleNextTestNotification();
        } else if (payload.startsWith('chain_reminder_') ||
            payload.startsWith('chain_prayer_time_')) {
          // Handle normal prayer time chain
          if (kDebugMode) {
            print('🔗 Handling prayer chain notification');
          }
          await _scheduleNextNotification();
        }
      }

      // Log successful handling
      if (kDebugMode) {
        print('✅ Notification response handled successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification response: $e');
      }
    }
  }

  static Future<void> _createNotificationChannels() async {
    // Channel for prayer reminders
    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
          'prayer_reminders',
          'Prayer Reminders',
          description: 'Notifications for prayer reminders',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );

    // Channel for prayer times
    const AndroidNotificationChannel prayerTimeChannel =
        AndroidNotificationChannel(
          'prayer_times',
          'Prayer Times',
          description: 'Notifications for prayer times',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adzan'),
        );

    // Channel for test notifications
    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_channel',
      'Test Notifications',
      description: 'Test notifications for debugging',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(reminderChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(prayerTimeChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(testChannel);
  }

  static Future<void> _requestNotificationPermissions() async {
    if (kDebugMode) {
      print('Requesting notification permissions...');
    }

    // Request permissions for iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request permissions for Android (API 33+)
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // Request basic notification permission
      final notificationPermission = await androidImplementation
          .requestNotificationsPermission();
      if (kDebugMode) {
        print('Notification permission granted: $notificationPermission');
      }

      // Note: requestExactAlarmsPermission and canScheduleExactAlarms are not available
      // in the current version of flutter_local_notifications.
      // Android will handle exact alarm permissions automatically for scheduled notifications.
      if (kDebugMode) {
        print(
          'Using AndroidScheduleMode.exactAllowWhileIdle for reliable notifications',
        );
      }
    }
  }

  // Find and schedule the next upcoming notification
  static Future<void> _scheduleNextNotification() async {
    final isEnabled = await PreferencesService.getNotificationsEnabled();
    if (!isEnabled) {
      if (kDebugMode) {
        print('Notifications disabled, skipping scheduling');
      }
      return;
    }

    final nextNotification = await _findNextNotification();
    if (nextNotification == null) {
      if (kDebugMode) {
        print('No more notifications to schedule');
      }
      return;
    }

    final notifType = nextNotification['type'] as String;
    final prayerName = nextNotification['prayer'] as String;
    final dateTime = nextNotification['dateTime'] as DateTime;
    final prayerTime = nextNotification['prayerTime'] as DateTime;

    if (notifType == 'reminder') {
      await _scheduleReminderNotification(
        prayerName,
        prayerTime,
        dateTime,
        isChained: true,
      );
    } else {
      await _schedulePrayerTimeNotification(
        prayerName,
        dateTime,
        isChained: true,
      );
    }

    if (kDebugMode) {
      final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');
      final malaysiaTime = tz.TZDateTime.from(dateTime, malaysiaTz);
      print('🔗 Scheduled next notification: $notifType for $prayerName');
      print(
        '   Local time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime)}',
      );
      print(
        '   Malaysia time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(malaysiaTime)}',
      );
    }
  }

  // Find the next notification that should be scheduled
  static Future<Map<String, dynamic>?> _findNextNotification() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Get current selected zone
    final zone = await PreferencesService.getSelectedZone();
    
    // Try today first
    final todayNotification = await _findNextNotificationForDate(zone, today, now);
    if (todayNotification != null) {
      return todayNotification;
    }
    
    // If no notification for today (i.e., after Isha), try tomorrow
    final tomorrowNotification = await _findNextNotificationForDate(zone, tomorrow, now);
    return tomorrowNotification;
  }

  // Helper method to find next notification for a specific date
  static Future<Map<String, dynamic>?> _findNextNotificationForDate(
    String zone, 
    DateTime targetDate, 
    DateTime currentTime,
  ) async {
    // Format date for database query
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final dateStr = dateFormat.format(targetDate);
    
    // Get prayer time from database
    final prayerTime = await DatabaseService.getPrayerTimeForDate(zone, dateStr);
    if (prayerTime == null) {
      if (kDebugMode) {
        print('No prayer time found for $dateStr in zone $zone');
      }
      return null;
    }
    
    final prayers = [
      {'name': 'Fajr', 'time': prayerTime.fajr},
      {'name': 'Dhuhr', 'time': prayerTime.dhuhr},
      {'name': 'Asr', 'time': prayerTime.asr},
      {'name': 'Maghrib', 'time': prayerTime.maghrib},
      {'name': 'Isha', 'time': prayerTime.isha},
    ];

    Map<String, dynamic>? nextNotification;
    DateTime? nextDateTime;

    for (final prayer in prayers) {
      final prayerName = prayer['name'] as String;
      final prayerTimeStr = prayer['time'] as String;

      final DateTime? prayerDateTime = _parseDateTime(targetDate, prayerTimeStr);
      if (prayerDateTime == null || prayerDateTime.isBefore(currentTime)) continue;

      // Check reminder time (10 minutes before) first
      final reminderDateTime = prayerDateTime.subtract(
        const Duration(minutes: 10),
      );
      
      // If reminder time is still in the future, that's our next notification
      if (reminderDateTime.isAfter(currentTime)) {
        nextDateTime = reminderDateTime;
        nextNotification = {
          'type': 'reminder',
          'prayer': prayerName,
          'dateTime': reminderDateTime,
          'prayerTime': prayerDateTime,
        };
        break; // Found the next notification, no need to check further
      }
      
      // If reminder time has passed but prayer time hasn't, schedule prayer time
      if (prayerDateTime.isAfter(currentTime)) {
        nextDateTime = prayerDateTime;
        nextNotification = {
          'type': 'prayer_time',
          'prayer': prayerName,
          'dateTime': prayerDateTime,
          'prayerTime': prayerDateTime,
        };
        break; // Found the next notification, no need to check further
      }
    }

    if (kDebugMode && nextNotification != null) {
      print('Found next notification for $dateStr: ${nextNotification!['type']} for ${nextNotification!['prayer']} at ${nextNotification!['dateTime']}');
    }

    return nextNotification;
  }

  static DateTime? _parseDateTime(DateTime date, String timeString) {
    try {
      // Handle different time formats: "06:15:00" or "06:15"
      final timeStr = timeString.length > 5
          ? timeString.substring(0, 5)
          : timeString;
      final timeParts = timeStr.split(':');

      if (timeParts.length < 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing time: $timeString');
      }
      return null;
    }
  }

  static Future<void> _scheduleReminderNotification(
    String prayerName,
    DateTime prayerTime,
    DateTime reminderTime, {
    bool isChained = false,
  }) async {
    try {
      final id = 1000; // Use fixed ID for single notification
      final timeStr = DateFormat('HH:mm').format(prayerTime);

      // Convert to Malaysia timezone (UTC+8)
      final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');
      final scheduledDate = tz.TZDateTime.from(reminderTime, malaysiaTz);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '$prayerName Prayer Reminder',
        '$prayerName prayer in 10 minutes at $timeStr',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_reminders',
            'Prayer Reminders',
            channelDescription: 'Notifications for prayer reminders',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notify',
            largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
            autoCancel: false,
            ongoing: false,
            showWhen: true,
            when: reminderTime.millisecondsSinceEpoch,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: isChained
            ? 'chain_reminder_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerTime)}'
            : 'reminder_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerTime)}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (kDebugMode) {
        print(
          '✅ Scheduled reminder for $prayerName at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(reminderTime)} (ID: $id)',
        );
        print(
          '   Malaysia Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(scheduledDate)}',
        );
        print(
          '   Timezone: ${scheduledDate.timeZoneName}, Offset: ${scheduledDate.timeZoneOffset}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling reminder for $prayerName: $e');
      }
    }
  }

  static Future<void> _schedulePrayerTimeNotification(
    String prayerName,
    DateTime prayerTime, {
    bool isChained = false,
  }) async {
    try {
      final id = 2000; // Use fixed ID for single notification

      // Convert to Malaysia timezone (UTC+8)
      final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');
      final scheduledDate = tz.TZDateTime.from(prayerTime, malaysiaTz);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '$prayerName Prayer Time',
        'It\'s time for $prayerName prayer',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_times',
            'Prayer Times',
            channelDescription: 'Notifications for prayer times',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notify',
            largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
            autoCancel: false,
            ongoing: false,
            showWhen: true,
            when: prayerTime.millisecondsSinceEpoch,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: isChained
            ? 'chain_prayer_time_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerTime)}'
            : 'prayer_time_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerTime)}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (kDebugMode) {
        print(
          '✅ Scheduled prayer time for $prayerName at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(prayerTime)} (ID: $id)',
        );
        print(
          '   Malaysia Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(scheduledDate)}',
        );
        print(
          '   Timezone: ${scheduledDate.timeZoneName}, Offset: ${scheduledDate.timeZoneOffset}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling prayer time for $prayerName: $e');
      }
    }
  }

  static Future<void> _showSystemNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required Importance importance,
    required Priority priority,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelId == 'prayer_reminders' ? 'Prayer Reminders' : 'Prayer Times',
          channelDescription: channelId == 'prayer_reminders'
              ? 'Notifications for prayer reminders'
              : 'Notifications for prayer times',
          importance: importance,
          priority: priority,
          enableVibration: true,
          playSound: true,
          icon: 'ic_notify',
          largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: channelId,
    );
  }

  static void _showInAppNotification({
    required String title,
    required String message,
    required bool isReminder,
  }) {
    // Store notification for display in UI
    final notification = {
      'title': title,
      'message': message,
      'time': DateFormat('HH:mm:ss').format(DateTime.now()),
      'isReminder': isReminder,
    };

    _recentNotifications.insert(0, notification);
    if (_recentNotifications.length > 10) {
      _recentNotifications.removeLast();
    }

    // Notify listeners if any
    _notificationController?.add(notification);
  }

  static Future<void> _playAdzan() async {
    try {
      // Check if adzan is enabled
      final isAdzanEnabled = await PreferencesService.getAdzanEnabled();
      if (!isAdzanEnabled) return;

      // Play the adzan sound
      await _audioPlayer.play(AssetSource('audio/adzan.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing adzan: $e');
      }
    }
  }

  // Store prayer times for chain scheduling
  static List<PrayerTime> _cachedPrayerTimes = [];

  static Future<void> scheduleNotificationsForPrayerTimes(
    List<PrayerTime> prayerTimes,
  ) async {
    // Cancel all existing scheduled notifications
    await cancelAllNotifications();

    // Store prayer times for chain scheduling
    _cachedPrayerTimes = prayerTimes;

    // Schedule only the next notification
    await _scheduleNextNotification();

    if (kDebugMode) {
      print(
        'Initialized chain scheduling',
      );
    }
  }

  static Future<void> cancelAllNotifications() async {
    // Cancel all scheduled notifications
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Reset notification ID counters
    _reminderNotificationId = 1000;
    _prayerNotificationId = 2000;

    if (kDebugMode) {
      print('Cancelled all scheduled notifications');
    }
  }

  // Method to get pending scheduled notifications for debugging
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Method to show debug information about scheduled notifications
  static Future<void> debugScheduledNotifications() async {
    final pending = await getPendingNotifications();

    if (kDebugMode) {
      print('=== SCHEDULED NOTIFICATIONS DEBUG ===');
      print('Total pending notifications: ${pending.length}');

      for (final notification in pending) {
        print('ID: ${notification.id}');
        print('Title: ${notification.title}');
        print('Body: ${notification.body}');
        print('Payload: ${notification.payload}');
        print('---');
      }

      // Group by type
      final reminders = pending
          .where((n) => n.payload?.startsWith('reminder_') == true)
          .length;
      final prayerTimes = pending
          .where((n) => n.payload?.startsWith('prayer_time_') == true)
          .length;

      print('Reminders scheduled: $reminders');
      print('Prayer time notifications scheduled: $prayerTimes');
      print('=== END DEBUG ===');
    }
  }

  // Method to test scheduling a notification for the next minute
  static Future<void> scheduleTestNotificationForNextMinute() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 1));

    try {
      final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        9999,
        'Test Scheduled Notification (1 min)',
        'This notification was scheduled for ${DateFormat('HH:mm').format(testTime)}',
        tz.TZDateTime.from(testTime, malaysiaTz),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_reminders',
            'Prayer Reminders',
            channelDescription: 'Test notification',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false,
            showWhen: true,
            visibility: NotificationVisibility.public,
            icon: 'ic_notify',
            largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'test_scheduled',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      _showInAppNotification(
        title: 'Test Scheduled (1 min)',
        message:
            'Scheduled test notification for ${DateFormat('HH:mm').format(testTime)}',
        isReminder: false,
      );

      if (kDebugMode) {
        print(
          '✅ Scheduled test notification for ${DateFormat('yyyy-MM-dd HH:mm:ss').format(testTime)}',
        );
        print('XXXXXXXXXXXXX');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling test notification: $e');
      }
    }
  }

  // Method to test scheduling a notification for the next 5 seconds (for immediate testing)
  static Future<void> scheduleTestNotificationFor5Seconds() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 5));

    print('🔍 DEBUG 5s: Current time: $now');
    print('🔍 DEBUG 5s: Scheduled time: $testTime');
    print('🔍 DEBUG 5s: Timezone: ${tz.local}');

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        9999,
        'Test Notification (5s)',
        'Scheduled at ${DateFormat('HH:mm:ss').format(now)}, should appear at ${DateFormat('HH:mm:ss').format(testTime)}',
        tz.TZDateTime.from(testTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notification - 5 seconds',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false,
            showWhen: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'test_scheduled_5s',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      _showInAppNotification(
        title: 'Test Scheduled (5s)',
        message:
            'Scheduled test notification for ${DateFormat('HH:mm:ss').format(testTime)} - wait 5 seconds!',
        isReminder: false,
      );

      if (kDebugMode) {
        print(
          '✅ Scheduled 5-second test notification for ${DateFormat('yyyy-MM-dd HH:mm:ss').format(testTime)}',
        );
        print('⏰ Current time: ${DateFormat('HH:mm:ss').format(now)}');
        print(
          '⏰ Expected notification time: ${DateFormat('HH:mm:ss').format(testTime)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling 5-second test notification: $e');
      }
    }
  }

  // Method to test scheduling a notification for the next 30 seconds (for immediate testing)
  static Future<void> scheduleTestNotificationFor30Seconds() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 30));

    print('🔍 DEBUG 30s: Current time: $now');
    print('🔍 DEBUG 30s: Scheduled time: $testTime');
    print('🔍 DEBUG 30s: Timezone: ${tz.local}');

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        9998,
        'Test Notification (30s)',
        'Scheduled at ${DateFormat('HH:mm:ss').format(now)}, should appear at ${DateFormat('HH:mm:ss').format(testTime)}',
        tz.TZDateTime.from(testTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notification - 30 seconds',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false,
            showWhen: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'test_scheduled_30s',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      _showInAppNotification(
        title: 'Test Scheduled (30s)',
        message:
            'Scheduled test notification for ${DateFormat('HH:mm:ss').format(testTime)} - wait 30 seconds!',
        isReminder: false,
      );

      if (kDebugMode) {
        print(
          '✅ Scheduled 30-second test notification for ${DateFormat('yyyy-MM-dd HH:mm:ss').format(testTime)}',
        );
        print('⏰ Current time: ${DateFormat('HH:mm:ss').format(now)}');
        print(
          '⏰ Expected notification time: ${DateFormat('HH:mm:ss').format(testTime)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling 30-second test notification: $e');
      }
    }
  }

  // Method to start 1-minute chain testing for debugging notification chaining
  static Future<void> startOneMinuteChainTest() async {
    if (kDebugMode) {
      print('🔥 Starting 1-minute chain test...');
    }

    // Cancel all existing notifications
    await cancelAllNotifications();

    // Schedule the first notification in 1 minute
    final now = DateTime.now();
    final firstNotificationTime = now.add(const Duration(minutes: 1));

    try {
      final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1000, // Use fixed ID for chaining
        'Chain Test Notification #1',
        'This is chain test #1 - scheduled for ${DateFormat('HH:mm:ss').format(firstNotificationTime)}',
        tz.TZDateTime.from(firstNotificationTime, malaysiaTz),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Chain test notification',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false,
            showWhen: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload:
            'chain_test_1', // This will trigger the next notification when tapped
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Set up test chain counter
      _testChainCounter = 1;

      _showInAppNotification(
        title: '🔥 Chain Test Started',
        message:
            'First notification scheduled for ${DateFormat('HH:mm:ss').format(firstNotificationTime)}. Tap notifications to continue chain!',
        isReminder: false,
      );

      if (kDebugMode) {
        print(
          '✅ Started 1-minute chain test. First notification at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(firstNotificationTime)}',
        );
        print('🔗 Tap the notification to trigger the next one in the chain!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting 1-minute chain test: $e');
      }
    }
  }

  // Counter for test chain
  static int _testChainCounter = 0;

  // Method to schedule the next test notification in the chain
  static Future<void> _scheduleNextTestNotification() async {
    _testChainCounter++;

    if (_testChainCounter > 10) {
      // Limit to 10 test notifications
      if (kDebugMode) {
        print('🏁 Test chain completed after 10 notifications');
      }

      // Show immediate notification indicating completion
      await _flutterLocalNotificationsPlugin.show(
        9995,
        '🏁 Test Chain Complete',
        'Chain test finished after 10 notifications at ${DateFormat('HH:mm:ss').format(DateTime.now())}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Chain test completion notification',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notify',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'chain_test_complete',
      );

      _showInAppNotification(
        title: '🏁 Test Chain Complete',
        message: 'Chain test finished after 10 notifications',
        isReminder: false,
      );
      return;
    }

    final now = DateTime.now();
    final nextNotificationTime = now.add(const Duration(minutes: 1));

    // First, show an immediate notification to confirm the chain is working
    try {
      await _flutterLocalNotificationsPlugin.show(
        9996,
        '🔗 Chain Test Response #${_testChainCounter - 1}',
        'Previous notification was tapped! Next scheduled for ${DateFormat('HH:mm:ss').format(nextNotificationTime)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Chain test response notification',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            icon: 'ic_notify',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'chain_test_response',
      );

      if (kDebugMode) {
        print(
          '✅ Showed immediate response notification for chain test #${_testChainCounter - 1}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing immediate response notification: $e');
      }
    }

    // Then schedule the next notification in the chain
    try {
      final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1000, // Use same fixed ID
        'Chain Test Notification #$_testChainCounter',
        'This is chain test #$_testChainCounter - scheduled for ${DateFormat('HH:mm:ss').format(nextNotificationTime)}. Tap to continue chain!',
        tz.TZDateTime.from(nextNotificationTime, malaysiaTz),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Chain test notification',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false,
            showWhen: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'chain_test_$_testChainCounter',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      _showInAppNotification(
        title: '🔗 Chain Test #$_testChainCounter Scheduled',
        message:
            'Next test notification at ${DateFormat('HH:mm:ss').format(nextNotificationTime)}. Previous tap confirmed!',
        isReminder: false,
      );

      if (kDebugMode) {
        print(
          '🔗 Scheduled next test notification #$_testChainCounter for ${DateFormat('yyyy-MM-dd HH:mm:ss').format(nextNotificationTime)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling next test notification: $e');
      }
    }
  }

  // Method to check Android system settings for notifications
  static Future<void> checkAndroidNotificationSystemStatus() async {
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null && kDebugMode) {
      print('=== ANDROID NOTIFICATION SYSTEM STATUS ===');

      try {
        // Check if notifications are enabled
        final areNotificationsEnabled = await androidImplementation
            .areNotificationsEnabled();
        print('Notifications enabled: $areNotificationsEnabled');
      } catch (e) {
        print('Could not check notification status: $e');
      }

      // Note: canScheduleExactAlarms is not available in current plugin version
      print('Using AndroidScheduleMode.exactAllowWhileIdle for scheduling');
      print('Android will handle exact alarm permissions automatically');

      try {
        // Check if notifications are enabled at app level
        final areNotificationsEnabled = await androidImplementation
            .areNotificationsEnabled();
        print('App notifications enabled: $areNotificationsEnabled');
      } catch (e) {
        print('Could not check app notification status: $e');
      }

      // Check timezone info
      final currentTz = tz.local;
      final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');
      final now = DateTime.now();
      final utcNow = now.toUtc();
      final tzNow = tz.TZDateTime.now(currentTz);
      final malaysiaNow = tz.TZDateTime.now(malaysiaTz);

      print('Device timezone: ${currentTz.name}');
      print('Malaysia timezone: ${malaysiaTz.name}');
      print('Device current time: $now');
      print('TZ current time: $tzNow');
      print('Malaysia current time: $malaysiaNow');
      print('UTC current time: $utcNow');

      // Check pending notifications
      try {
        final pendingNotifications = await _flutterLocalNotificationsPlugin
            .pendingNotificationRequests();
        print('Pending notifications count: ${pendingNotifications.length}');
        if (pendingNotifications.isNotEmpty) {
          print('Next few pending notifications:');
          for (int i = 0; i < math.min(5, pendingNotifications.length); i++) {
            final notif = pendingNotifications[i];
            print('  ID ${notif.id}: ${notif.title} - ${notif.body}');
          }
        }
      } catch (e) {
        print('Could not fetch pending notifications: $e');
      }

      print('=== END SYSTEM STATUS ===');
    }
  }

  static Future<void> showTestNotification() async {
    if (kDebugMode) {
      print('🔔 Showing immediate test notification...');
    }

    // Show system notification
    await _showSystemNotification(
      id: 999,
      title: 'Test Notification',
      body:
          'This is a test system notification - ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      channelId: 'prayer_reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    if (kDebugMode) {
      print('✅ Immediate test notification sent');
    }

    // Show in-app notification
    _showInAppNotification(
      title: 'Test Notification',
      message:
          'This is a test notification - ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      isReminder: false,
    );
  }

  // Test immediate notification with high priority settings
  static Future<void> showImmediateTestNotification() async {
    if (kDebugMode) {
      print('🚨 Showing HIGH PRIORITY immediate test notification...');
    }

    try {
      await _flutterLocalNotificationsPlugin.show(
        9999,
        '🚨 IMMEDIATE TEST',
        'This notification should appear RIGHT NOW at ${DateFormat('HH:mm:ss').format(DateTime.now())}! If you see this, immediate notifications work.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Immediate test notification',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false,
            showWhen: true,
            visibility: NotificationVisibility.public,
            icon: 'ic_notify',
            largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'immediate_test',
      );

      if (kDebugMode) {
        print('✅ HIGH PRIORITY immediate notification sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending immediate notification: $e');
      }
    }

    // Show in-app notification
    _showInAppNotification(
      title: '🚨 Immediate Test Sent',
      message:
          'High priority notification sent at ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      isReminder: false,
    );
  }

  static Future<void> testReminderNotification() async {
    // Show system notification
    await _showSystemNotification(
      id: 998,
      title: 'Test Prayer Reminder',
      body: 'Test: Dhuhr prayer in 10 minutes at 12:30',
      channelId: 'prayer_reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    // Show in-app notification
    _showInAppNotification(
      title: 'Test Prayer Reminder',
      message: 'Test: Dhuhr prayer in 10 minutes at 12:30',
      isReminder: true,
    );
  }

  static Future<void> testPrayerTimeNotification() async {
    // Show system notification
    await _showSystemNotification(
      id: 997,
      title: 'Test Prayer Time',
      body: 'Test: It\'s time for Dhuhr prayer',
      channelId: 'prayer_times',
      importance: Importance.max,
      priority: Priority.max,
    );

    // Show in-app notification
    _showInAppNotification(
      title: 'Test Prayer Time',
      message: 'Test: It\'s time for Dhuhr prayer',
      isReminder: false,
    );
    // await testAdzanPlayback();
  }

  static Future<void> testAdzanPlayback() async {
    try {
      await _audioPlayer.play(AssetSource('audio/adzan.mp3'));
      _showInAppNotification(
        title: 'Audio Test',
        message: 'Adzan playback started',
        isReminder: false,
      );
    } catch (e) {
      _showInAppNotification(
        title: 'Audio Test Failed',
        message: 'Error: $e',
        isReminder: false,
      );
    }
  }

  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _showInAppNotification(
        title: 'Audio Stopped',
        message: 'Adzan playback stopped',
        isReminder: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping audio: $e');
      }
    }
  }

  // Initialize stream controller for listening to notifications
  static void enableNotificationStream() {
    _notificationController ??=
        StreamController<Map<String, dynamic>>.broadcast();
  }

  static void disableNotificationStream() {
    _notificationController?.close();
    _notificationController = null;
  }

  static void dispose() {
    _audioPlayer.dispose();
  }
}
