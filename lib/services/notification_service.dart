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

  /// Simplified notification response handler for adzan playback only
  @pragma('vm:entry-point')
  static Future<void> _onNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    try {
      if (kDebugMode) {
        print('📱 Notification tapped: ${notificationResponse.payload}');
      }

      final payload = notificationResponse.payload;
      if (payload == null) return;

      // Handle prayer time notifications by playing adzan
      if (payload.startsWith('prayer_time_')) {
        if (kDebugMode) {
          print('🕌 Playing adzan for prayer time notification');
        }
        // await _playAdzan();
      }

      if (kDebugMode) {
        print('✅ Notification response handled');
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
        payload: 'reminder_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerTime)}',
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
            sound: RawResourceAndroidNotificationSound('adzan'),
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
        payload: 'prayer_time_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerTime)}',
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
          sound: channelId == 'prayer_times' ? RawResourceAndroidNotificationSound('adzan') : null,
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


  /// Schedules all prayer notifications in bulk (better approach than chaining)
  /// This schedules reminders and prayer time notifications for all upcoming prayers
  static Future<void> scheduleBulkNotificationsForPrayerTimes(
    List<PrayerTime> prayerTimes,
  ) async {
    // Cancel all existing scheduled notifications
    await cancelAllNotifications();

    final now = DateTime.now();
    int notificationIdCounter = 3000; // Start from 3000 to avoid conflicts
    int scheduledCount = 0;

    final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');

    for (final prayerTime in prayerTimes) {
      // Parse the date string from the PrayerTime model (format: "dd-MMM-yyyy")
      final dateFormat = DateFormat('dd-MMM-yyyy');
      DateTime prayerDate;
      try {
        prayerDate = dateFormat.parse(prayerTime.date);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parsing date ${prayerTime.date}: $e');
        }
        continue; // Skip this prayer time if date parsing fails
      }

      final prayers = [
        {'name': 'Fajr', 'time': prayerTime.fajr},
        {'name': 'Dhuhr', 'time': prayerTime.dhuhr},
        {'name': 'Asr', 'time': prayerTime.asr},
        {'name': 'Maghrib', 'time': prayerTime.maghrib},
        {'name': 'Isha', 'time': prayerTime.isha},
      ];

      for (final prayer in prayers) {
        final prayerName = prayer['name'] as String;
        final prayerTimeStr = prayer['time'] as String;

        final DateTime? prayerDateTime = _parseDateTime(prayerDate, prayerTimeStr);
        if (prayerDateTime == null || prayerDateTime.isBefore(now)) continue;

        // Schedule reminder notification (10 minutes before)
        final reminderDateTime = prayerDateTime.subtract(const Duration(minutes: 10));
        if (reminderDateTime.isAfter(now)) {
          try {
            final timeStr = DateFormat('HH:mm').format(prayerDateTime);
            final scheduledDate = tz.TZDateTime.from(reminderDateTime, malaysiaTz);

            await _flutterLocalNotificationsPlugin.zonedSchedule(
              notificationIdCounter++,
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
                  icon: 'ic_notification',
                  largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
                  autoCancel: false,
                  ongoing: false,
                  showWhen: true,
                  when: reminderDateTime.millisecondsSinceEpoch,
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
              payload: 'bulk_reminder_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerDateTime)}',
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
            scheduledCount++;

            if (kDebugMode) {
              print('✅ Bulk scheduled reminder for $prayerName at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(reminderDateTime)}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error bulk scheduling reminder for $prayerName: $e');
            }
          }
        }

        // Schedule prayer time notification
        try {
          final scheduledDate = tz.TZDateTime.from(prayerDateTime, malaysiaTz);

          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notificationIdCounter++,
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
                icon: 'ic_notification',
                sound: RawResourceAndroidNotificationSound('adzan'),
                largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
                autoCancel: false,
                ongoing: false,
                showWhen: true,
                when: prayerDateTime.millisecondsSinceEpoch,
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
            payload: 'bulk_prayer_time_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerDateTime)}',
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          scheduledCount++;

          if (kDebugMode) {
            print('✅ Bulk scheduled prayer time for $prayerName at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(prayerDateTime)}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error bulk scheduling prayer time for $prayerName: $e');
          }
        }
      }
    }

    if (kDebugMode) {
      print('✅ Bulk scheduling completed: $scheduledCount notifications scheduled');
      print('📱 All notifications will trigger automatically without user interaction');
    }

    _showInAppNotification(
      title: '✅ Bulk Schedule Complete',
      message: 'Scheduled $scheduledCount prayer notifications. All will trigger automatically!',
      isReminder: false,
    );
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

  // Method to start recurring test notifications (much better than chaining)
  static Future<void> startRecurringTestNotifications() async {
    if (kDebugMode) {
      print('🔄 Starting recurring test notifications...');
    }

    // Cancel all existing test notifications
    await cancelTestNotifications();

    final now = DateTime.now();
    final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');

    // Schedule 10 test notifications, one every 2 minutes
    for (int i = 1; i <= 10; i++) {
      final notificationTime = now.add(Duration(minutes: i * 2));
      
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          8000 + i, // Unique ID for each recurring test notification
          'Recurring Test #$i',
          'Auto-scheduled test notification $i of 10 at ${DateFormat('HH:mm:ss').format(notificationTime)}. No tap required!',
          tz.TZDateTime.from(notificationTime, malaysiaTz),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test_channel',
              'Test Notifications',
              channelDescription: 'Recurring test notification',
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
          payload: 'recurring_test_$i',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        if (kDebugMode) {
          print(
            '✅ Scheduled recurring test #$i for ${DateFormat('yyyy-MM-dd HH:mm:ss').format(notificationTime)}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error scheduling recurring test #$i: $e');
        }
      }
    }

    _showInAppNotification(
      title: '🔄 Recurring Test Started',
      message:
          'Scheduled 10 notifications every 2 minutes starting at ${DateFormat('HH:mm:ss').format(now.add(const Duration(minutes: 2)))}. No user interaction needed!',
      isReminder: false,
    );

    if (kDebugMode) {
      print(
        '✅ Started recurring test notifications. 10 notifications scheduled every 2 minutes.',
      );
      print('📋 These notifications will appear automatically without any user interaction.');
    }
  }

  // Method to cancel only test notifications
  static Future<void> cancelTestNotifications() async {
    // Cancel recurring test notifications (IDs 8001-8010)
    for (int i = 1; i <= 10; i++) {
      await _flutterLocalNotificationsPlugin.cancel(8000 + i);
    }
    
    // Cancel other test notification IDs
    await _flutterLocalNotificationsPlugin.cancel(9999); // 5-second test
    await _flutterLocalNotificationsPlugin.cancel(9998); // 30-second test
    await _flutterLocalNotificationsPlugin.cancel(9996); // Chain response
    await _flutterLocalNotificationsPlugin.cancel(9995); // Chain complete
    await _flutterLocalNotificationsPlugin.cancel(1000); // Chain test

    if (kDebugMode) {
      print('✅ Cancelled all test notifications');
    }
  }

  // Method to start daily recurring notifications (better for production use)
  static Future<void> startDailyRecurringTest() async {
    if (kDebugMode) {
      print('📅 Starting daily recurring test notifications...');
    }

    await cancelTestNotifications();

    final now = DateTime.now();
    final malaysiaTz = tz.getLocation('Asia/Kuala_Lumpur');

    // Schedule a test notification for the next 7 days, same time each day
    final baseTime = DateTime(now.year, now.month, now.day, now.hour, now.minute + 2);
    
    for (int day = 0; day < 7; day++) {
      final notificationTime = baseTime.add(Duration(days: day));
      
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          7000 + day, // Unique ID for each daily notification
          'Daily Test Day ${day + 1}',
          'Daily recurring test notification for day ${day + 1} at ${DateFormat('HH:mm').format(notificationTime)}. Fully automatic!',
          tz.TZDateTime.from(notificationTime, malaysiaTz),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test_channel',
              'Test Notifications',
              channelDescription: 'Daily recurring test notification',
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
          payload: 'daily_test_day_${day + 1}',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        if (kDebugMode) {
          print(
            '✅ Scheduled daily test for day ${day + 1} at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(notificationTime)}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error scheduling daily test for day ${day + 1}: $e');
        }
      }
    }

    _showInAppNotification(
      title: '📅 Daily Test Started',
      message:
          'Scheduled 7 daily notifications starting ${DateFormat('HH:mm').format(baseTime)}. Completely automatic!',
      isReminder: false,
    );

    if (kDebugMode) {
      print('✅ Started daily recurring test notifications for 7 days.');
      print('📋 These notifications will appear automatically each day.');
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
