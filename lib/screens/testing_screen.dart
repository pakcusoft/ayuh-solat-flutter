import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class TestingScreen extends StatelessWidget {
  const TestingScreen({super.key});

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
                  label: 'Test Prayer Time + Adzan',
                  icon: Icons.mosque,
                  color: Colors.green,
                  onPressed: () async {
                    await NotificationService.testPrayerTimeNotification();
                    _showSnackBar(
                      context,
                      'Test prayer time notification + adzan sent!',
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: 'Stop Audio',
                  icon: Icons.stop,
                  color: Colors.red,
                  onPressed: () async {
                    await NotificationService.stopAudio();
                    _showSnackBar(context, 'Audio stopped!');
                  },
                ),
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

            // Chain notifications section
            _buildSection(
              context: context,
              title: 'Chain Notifications',
              icon: Icons.link,
              children: [
                const Text(
                  'Test notification chaining (tap notifications to continue chain):',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  context: context,
                  label: '🔥 Test 1-Minute Chain',
                  icon: Icons.link,
                  color: Colors.deepPurple,
                  onPressed: () async {
                    await NotificationService.startOneMinuteChainTest();
                    _showSnackBar(
                      context,
                      '🔥 1-minute chain test started! First notification in 1 minute. TAP notifications to continue chain!',
                      duration: 4,
                    );
                  },
                ),
              ],
            ),

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
                      '• Chain notifications require you to tap each notification to trigger the next one.\n'
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
