import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/prayer_time.dart';
import 'preferences_service.dart';

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
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // For in-app notifications
  static final List<Map<String, dynamic>> _recentNotifications = [];
  static StreamController<Map<String, dynamic>>? _notificationController;
  
  // Notification ID counters
  static int _reminderNotificationId = 1000;
  static int _prayerNotificationId = 2000;
  
  // Getters for UI access
  static List<Map<String, dynamic>> get recentNotifications => _recentNotifications;
  static Stream<Map<String, dynamic>>? get notificationStream => _notificationController?.stream;
  
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('NotificationService initialized');
    }
    
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Request notification permissions
    await _requestNotificationPermissions();
  }
  
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings initializationSettingsIOS = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tap
        if (kDebugMode) {
          print('Notification tapped: ${notificationResponse.payload}');
        }
        
        // Handle prayer time notifications by playing adzan
        if (notificationResponse.payload?.startsWith('prayer_time_') == true) {
          await _playAdzan();
        }
      },
    );
    
    // Create notification channels for Android
    await _createNotificationChannels();
  }
  
  static Future<void> _createNotificationChannels() async {
    // Channel for prayer reminders
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'prayer_reminders',
      'Prayer Reminders',
      description: 'Notifications for prayer reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    
    // Channel for prayer times
    const AndroidNotificationChannel prayerTimeChannel = AndroidNotificationChannel(
      'prayer_times',
      'Prayer Times',
      description: 'Notifications for prayer times',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(prayerTimeChannel);
  }
  
  static Future<void> _requestNotificationPermissions() async {
    // Request permissions for iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Request permissions for Android (API 33+)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
  
  static Future<void> _scheduleNotificationsForDate(PrayerTime prayerTime) async {
    final isEnabled = await PreferencesService.getNotificationsEnabled();
    if (!isEnabled) return;
    
    // Parse the date from the prayer time
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final DateTime date;
    try {
      date = dateFormat.parse(prayerTime.date);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date: ${prayerTime.date}');
      }
      return;
    }
    
    // Skip dates in the past (except today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate.isBefore(today)) {
      return;
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
      
      // Parse prayer time
      final DateTime? prayerDateTime = _parseDateTime(date, prayerTimeStr);
      if (prayerDateTime == null) continue;
      
      // Skip past prayer times for today
      if (targetDate.isAtSameMomentAs(today) && prayerDateTime.isBefore(now)) {
        continue;
      }
      
      // Schedule reminder (10 minutes before)
      final reminderDateTime = prayerDateTime.subtract(const Duration(minutes: 10));
      if (reminderDateTime.isAfter(now)) {
        await _scheduleReminderNotification(prayerName, prayerDateTime, reminderDateTime);
      }
      
      // Schedule prayer time notification
      if (prayerDateTime.isAfter(now)) {
        await _schedulePrayerTimeNotification(prayerName, prayerDateTime);
      }
    }
  }
  
  static DateTime? _parseDateTime(DateTime date, String timeString) {
    try {
      // Handle different time formats: "06:15:00" or "06:15"
      final timeStr = timeString.length > 5 ? timeString.substring(0, 5) : timeString;
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
    DateTime reminderTime
  ) async {
    final id = _reminderNotificationId++;
    final timeStr = DateFormat('HH:mm').format(prayerTime);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '$prayerName Prayer Reminder',
      '$prayerName prayer in 10 minutes at $timeStr',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminders',
          'Prayer Reminders',
          channelDescription: 'Notifications for prayer reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      payload: 'reminder_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerTime)}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    if (kDebugMode) {
      print('Scheduled reminder for $prayerName at ${DateFormat('yyyy-MM-dd HH:mm').format(reminderTime)}');
    }
  }
  
  static Future<void> _schedulePrayerTimeNotification(
    String prayerName, 
    DateTime prayerTime
  ) async {
    final id = _prayerNotificationId++;
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '$prayerName Prayer Time',
      'It\'s time for $prayerName prayer',
      tz.TZDateTime.from(prayerTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_times',
          'Prayer Times',
          channelDescription: 'Notifications for prayer times',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/launcher_icon',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      payload: 'prayer_time_${prayerName}_${DateFormat('yyyy-MM-dd').format(prayerTime)}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    if (kDebugMode) {
      print('Scheduled prayer time notification for $prayerName at ${DateFormat('yyyy-MM-dd HH:mm').format(prayerTime)}');
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
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelId == 'prayer_reminders' ? 'Prayer Reminders' : 'Prayer Times',
      channelDescription: channelId == 'prayer_reminders' 
          ? 'Notifications for prayer reminders'
          : 'Notifications for prayer times',
      importance: importance,
      priority: priority,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
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
  
  static Future<void> scheduleNotificationsForPrayerTimes(List<PrayerTime> prayerTimes) async {
    // Cancel all existing scheduled notifications
    await cancelAllNotifications();
    
    // Schedule notifications for each day
    for (final prayerTime in prayerTimes) {
      await _scheduleNotificationsForDate(prayerTime);
    }
    
    if (kDebugMode) {
      print('Scheduled notifications for ${prayerTimes.length} days of prayer times');
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
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
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
      final reminders = pending.where((n) => n.payload?.startsWith('reminder_') == true).length;
      final prayerTimes = pending.where((n) => n.payload?.startsWith('prayer_time_') == true).length;
      
      print('Reminders scheduled: $reminders');
      print('Prayer time notifications scheduled: $prayerTimes');
      print('=== END DEBUG ===');
    }
  }
  
  // Method to test scheduling a notification for the next minute
  static Future<void> scheduleTestNotificationForNextMinute() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 1));
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      9999,
      'Test Scheduled Notification',
      'This notification was scheduled for ${DateFormat('HH:mm').format(testTime)}',
      tz.TZDateTime.from(testTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminders',
          'Prayer Reminders',
          channelDescription: 'Test notification',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_scheduled',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    _showInAppNotification(
      title: 'Test Scheduled',
      message: 'Scheduled test notification for ${DateFormat('HH:mm').format(testTime)}',
      isReminder: false,
    );
    
    if (kDebugMode) {
      print('Scheduled test notification for ${DateFormat('yyyy-MM-dd HH:mm').format(testTime)}');
    }
  }
  
  static Future<void> showTestNotification() async {
    // Show system notification
    await _showSystemNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a test system notification - ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      channelId: 'prayer_reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    // Show in-app notification
    _showInAppNotification(
      title: 'Test Notification',
      message: 'This is a test notification - ${DateFormat('HH:mm:ss').format(DateTime.now())}',
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
    await testAdzanPlayback();
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
    _notificationController ??= StreamController<Map<String, dynamic>>.broadcast();
  }
  
  static void disableNotificationStream() {
    _notificationController?.close();
    _notificationController = null;
  }
  
  static void dispose() {
    _audioPlayer.dispose();
  }
}
