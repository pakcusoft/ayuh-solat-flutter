import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/prayer_time.dart';
import 'preferences_service.dart';

class NotificationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Timer? _prayerCheckTimer;
  static List<PrayerTime> _prayerTimes = [];
  static final Set<String> _notifiedReminders = {};
  static final Set<String> _notifiedPrayerTimes = {};
  
  // Flutter local notifications
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // For in-app notifications
  static final List<Map<String, dynamic>> _recentNotifications = [];
  static StreamController<Map<String, dynamic>>? _notificationController;
  
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
    
    // Start periodic prayer time checking
    _startPrayerTimeMonitoring();
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
  
  static void _startPrayerTimeMonitoring() {
    // Check every minute for prayer times and reminders
    _prayerCheckTimer?.cancel();
    _prayerCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkPrayerTimes();
    });
  }
  
  static void _checkPrayerTimes() async {
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    
    // Use the same date format as stored in database: dd-MMM-yyyy
    final currentDate = DateFormat('dd-MMM-yyyy').format(now);
    
    if (kDebugMode) {
      print('NotificationService: Checking at $currentTime on $currentDate');
      print('NotificationService: Available prayer times: ${_prayerTimes.length}');
      if (_prayerTimes.isNotEmpty) {
        print('NotificationService: First prayer time date format: "${_prayerTimes.first.date}"');
      }
    }
    
    // Find today's prayer times using the correct date format
    final todayPrayerTime = _prayerTimes.cast<PrayerTime?>().firstWhere(
      (pt) => pt?.date == currentDate,
      orElse: () => null,
    );
    
    if (todayPrayerTime == null) {
      if (kDebugMode) {
        print('NotificationService: No prayer times found for today ($currentDate)');
      }
      return;
    }
    
    if (kDebugMode) {
      print('NotificationService: Found prayer times for today: ${todayPrayerTime.date}');
    }
    
    final prayers = [
      {'name': 'Fajr', 'time': todayPrayerTime.fajr},
      {'name': 'Dhuhr', 'time': todayPrayerTime.dhuhr},
      {'name': 'Asr', 'time': todayPrayerTime.asr},
      {'name': 'Maghrib', 'time': todayPrayerTime.maghrib},
      {'name': 'Isha', 'time': todayPrayerTime.isha},
    ];
    
    for (final prayer in prayers) {
      final prayerName = prayer['name'] as String;
      final prayerTime = prayer['time'] as String;
      final prayerTimeFormatted = _formatTimeForComparison(prayerTime);
      final reminderTime = _subtractMinutes(prayerTimeFormatted, 10);
      
      // Check for 10-minute reminder
      if (currentTime == reminderTime) {
        final reminderKey = '$currentDate-$prayerName-reminder';
        if (!_notifiedReminders.contains(reminderKey)) {
          await _showReminderNotification(prayerName, prayerTimeFormatted);
          _notifiedReminders.add(reminderKey);
        }
      }
      
      // Check for prayer time
      if (currentTime == prayerTimeFormatted) {
        final prayerKey = '$currentDate-$prayerName-prayer';
        if (!_notifiedPrayerTimes.contains(prayerKey)) {
          await _showPrayerTimeNotification(prayerName);
          await _playAdzan();
          _notifiedPrayerTimes.add(prayerKey);
        }
      }
    }
  }
  
  static String _formatTimeForComparison(String time) {
    // Convert 06:15:00 to 06:15
    if (time.length > 5) {
      return time.substring(0, 5);
    }
    return time;
  }
  
  static String _subtractMinutes(String time, int minutes) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final dateTime = DateTime(2024, 1, 1, hour, minute);
      final newDateTime = dateTime.subtract(Duration(minutes: minutes));
      
      return DateFormat('HH:mm').format(newDateTime);
    } catch (e) {
      return time;
    }
  }
  
  static Future<void> _showReminderNotification(String prayerName, String prayerTime) async {
    final isEnabled = await PreferencesService.getNotificationsEnabled();
    if (!isEnabled) return;
    
    if (kDebugMode) {
      print('Prayer reminder: $prayerName prayer in 10 minutes at $prayerTime');
    }
    
    // Show system notification
    await _showSystemNotification(
      id: prayerName.hashCode + 1,
      title: '$prayerName Prayer Reminder',
      body: '$prayerName prayer in 10 minutes at $prayerTime',
      channelId: 'prayer_reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    // Show in-app notification
    _showInAppNotification(
      title: '$prayerName Prayer Reminder',
      message: '$prayerName prayer in 10 minutes at $prayerTime',
      isReminder: true,
    );
  }
  
  static Future<void> _showPrayerTimeNotification(String prayerName) async {
    final isEnabled = await PreferencesService.getNotificationsEnabled();
    if (!isEnabled) return;
    
    if (kDebugMode) {
      print('Prayer time notification: It\'s time for $prayerName prayer');
    }
    
    // Show system notification
    await _showSystemNotification(
      id: prayerName.hashCode + 2,
      title: '$prayerName Prayer Time',
      body: 'It\'s time for $prayerName prayer',
      channelId: 'prayer_times',
      importance: Importance.max,
      priority: Priority.max,
    );
    
    // Show in-app notification
    _showInAppNotification(
      title: '$prayerName Prayer Time',
      message: 'It\'s time for $prayerName prayer',
      isReminder: false,
    );
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
    // Store prayer times for monitoring
    _prayerTimes = prayerTimes;
    
    // Clear previous notifications tracking
    _notifiedReminders.clear();
    _notifiedPrayerTimes.clear();
    
    if (kDebugMode) {
      print('Updated prayer times for notification monitoring: ${prayerTimes.length} days');
    }
  }
  
  static Future<void> cancelAllNotifications() async {
    // Clear notification tracking
    _notifiedReminders.clear();
    _notifiedPrayerTimes.clear();
    
    if (kDebugMode) {
      print('Cancelled all notifications');
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
    _prayerCheckTimer?.cancel();
    _audioPlayer.dispose();
  }
}
