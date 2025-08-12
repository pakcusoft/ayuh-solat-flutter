import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import 'dart:async';

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  List<PendingNotificationRequest> _pendingNotifications = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _updatePendingNotifications();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _updatePendingNotifications();
      }
    });
  }

  Future<void> _updatePendingNotifications() async {
    try {
      final pendingNotifications = await NotificationService.getPendingNotifications();
      if (mounted) {
        setState(() {
          _pendingNotifications = pendingNotifications;
        });
      }
    } catch (e) {
      print('Error fetching pending notifications: $e');
    }
  }

  IconData _getNotificationIcon(String? payload) {
    if (payload == null) return Icons.notifications;
    
    if (payload.contains('reminder')) {
      return Icons.timer;
    } else if (payload.contains('prayer_time')) {
      return Icons.mosque;
    } else if (payload.contains('test')) {
      return Icons.science;
    } else if (payload.contains('chain')) {
      return Icons.link;
    } else if (payload.contains('recurring')) {
      return Icons.repeat;
    } else if (payload.contains('daily')) {
      return Icons.calendar_today;
    } else if (payload.contains('bulk')) {
      return Icons.schedule_send;
    }
    
    return Icons.notification_important;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Card(
              elevation: 2,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bug_report,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Notification Testing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test various notification functions to ensure they work properly on your device.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Immediate notifications section
            _buildSection(
              context: context,
              title: 'Immediate Notifications',
              icon: Icons.notifications_active,
              children: [
                _buildTestButton(
                  context: context,
                  label: 'Test Basic Notification',
                  icon: Icons.notification_add,
                  onPressed: () async {
                    await NotificationService.showTestNotification();
                    _showSnackBar(context, 'Test notification sent!');
                  },
                ),
                // const SizedBox(height: 8),
                // _buildTestButton(
                //   context: context,
                //   label: '🚨 Test IMMEDIATE Notification',
                //   icon: Icons.priority_high,
                //   color: Colors.red,
                //   onPressed: () async {
                //     await NotificationService.showImmediateTestNotification();
                //     _showSnackBar(context, '🚨 HIGH PRIORITY immediate test sent!');
                //   },
                // ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: 'Test Prayer Reminder',
                  icon: Icons.schedule,
                  color: Colors.orange,
                  onPressed: () async {
                    await NotificationService.testReminderNotification();
                    _showSnackBar(context, 'Test reminder sent!');
                  },
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: 'Test Prayer Time',
                  icon: Icons.mosque,
                  color: Colors.green,
                  onPressed: () async {
                    await NotificationService.testPrayerTimeNotification();
                    _showSnackBar(
                      context,
                      'Test prayer time notification!',
                    );
                  },
                ),
                // const SizedBox(height: 8),
                // _buildTestButton(
                //   context: context,
                //   label: 'Stop Audio',
                //   icon: Icons.stop,
                //   color: Colors.red,
                //   onPressed: () async {
                //     await NotificationService.stopAudio();
                //     _showSnackBar(context, 'Audio stopped!');
                //   },
                // ),
              ],
            ),

            const SizedBox(height: 16),

            // Scheduled notifications section
            _buildSection(
              context: context,
              title: 'Scheduled Notifications',
              icon: Icons.schedule,
              children: [
                const Text(
                  'Test scheduled notifications (can close app after scheduling):',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                // const SizedBox(height: 8),
                // _buildTestButton(
                //   context: context,
                //   label: 'Test 5-Second Schedule',
                //   icon: Icons.timer_3,
                //   color: Colors.purple,
                //   onPressed: () async {
                //     await NotificationService.scheduleTestNotificationFor5Seconds();
                //     _showSnackBar(
                //       context,
                //       'Test notification scheduled for 5 seconds! Wait and see...',
                //       duration: 3,
                //     );
                //   },
                // ),
                // const SizedBox(height: 8),
                // _buildTestButton(
                //   context: context,
                //   label: 'Test 30-Second Schedule',
                //   icon: Icons.timer,
                //   color: Colors.deepOrange,
                //   onPressed: () async {
                //     await NotificationService.scheduleTestNotificationFor30Seconds();
                //     _showSnackBar(
                //       context,
                //       'Test notification scheduled for 30 seconds! You can close the app.',
                //       duration: 4,
                //     );
                //   },
                // ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: 'Test 1-Minute Schedule',
                  icon: Icons.timer,
                  color: Colors.indigo,
                  onPressed: () async {
                    await NotificationService.scheduleTestNotificationForNextMinute();
                    _showSnackBar(
                      context,
                      'Test notification scheduled for 1 minute! You can close the app to test.',
                      duration: 4,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Recurring notifications section
            _buildSection(
              context: context,
              title: 'Recurring Notifications',
              icon: Icons.repeat,
              children: [
                const Text(
                  'Test automatic recurring notifications (no user interaction required):',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: '🔄 Every 2 Minutes (10x)',
                  icon: Icons.repeat,
                  color: Colors.deepPurple,
                  onPressed: () async {
                    await NotificationService.startRecurringTestNotifications();
                    _showSnackBar(
                      context,
                      '🔄 Recurring test started! 10 notifications every 2 minutes. NO user interaction needed!',
                      duration: 4,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: '📅 Daily Test (7 days)',
                  icon: Icons.calendar_month,
                  color: Colors.indigo,
                  onPressed: () async {
                    await NotificationService.startDailyRecurringTest();
                    _showSnackBar(
                      context,
                      '📅 Daily recurring test started! 1 notification per day for 7 days. Completely automatic!',
                      duration: 4,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: '❌ Cancel All Tests',
                  icon: Icons.cancel,
                  color: Colors.red,
                  onPressed: () async {
                    await NotificationService.cancelTestNotifications();
                    _showSnackBar(
                      context,
                      '❌ All test notifications cancelled successfully.',
                      duration: 3,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pending notifications section
            _buildPendingNotifications(),

            const SizedBox(height: 16),

            // System diagnostics section
            _buildSection(
              context: context,
              title: 'System Diagnostics',
              icon: Icons.settings_system_daydream,
              children: [
                _buildTestButton(
                  context: context,
                  label: '📋 Check System Status',
                  icon: Icons.info,
                  color: Colors.blue,
                  onPressed: () async {
                    await NotificationService.checkAndroidNotificationSystemStatus();
                    _showSnackBar(
                      context,
                      '📋 System status logged to console. Check logs for details.',
                      duration: 3,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: '🔍 Debug Scheduled Notifications',
                  icon: Icons.bug_report,
                  color: Colors.teal,
                  onPressed: () async {
                    await NotificationService.debugScheduledNotifications();
                    _showSnackBar(
                      context,
                      '🔍 Scheduled notifications debug info logged to console.',
                      duration: 3,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Warning section
            Card(
              elevation: 2,
              color: Colors.yellow.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Testing Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• For scheduled notifications, you can close the app after scheduling to test background functionality.\n'
                      '• Check your device\'s notification settings if notifications don\'t appear.\n'
                      '• Recurring notifications are fully automatic and don\'t require user interaction.\n'
                      '• Use "Cancel All Tests" to stop recurring notification tests.\n'
                      '• Check the debug console/logs for detailed information about notification status.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingNotifications() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pending Reminders (${_pendingNotifications.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _updatePendingNotifications,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _pendingNotifications.isEmpty
                  ? 'No pending notifications scheduled'
                  : 'Scheduled notifications that will trigger automatically (refreshes every 10s)',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            if (_pendingNotifications.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No notifications scheduled',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _pendingNotifications.take(10).map((notification) {
                  String displayTitle = notification.title ?? 'Unknown';
                  String displayBody = notification.body ?? '';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(0.05),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getNotificationIcon(notification.payload),
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'ID: ${notification.id}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[500],
                              ),
                            ),
                          ],
                        ),
                        if (displayBody.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              displayBody,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (notification.payload != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Type: ${notification.payload}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[400],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (_pendingNotifications.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${_pendingNotifications.length - 10} more notifications',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {int duration = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
      ),
    );
  }
}
