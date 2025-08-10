import 'package:flutter/material.dart';
import '../services/prayer_time_service.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';
import 'weekly_schedule_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedZone = 'WLY01';
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _adzanEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedZone = await PreferencesService.getSelectedZone();
    final notificationsEnabled =
        await PreferencesService.getNotificationsEnabled();
    final adzanEnabled = await PreferencesService.getAdzanEnabled();

    setState(() {
      _selectedZone = savedZone;
      _notificationsEnabled = notificationsEnabled;
      _adzanEnabled = adzanEnabled;
      _isLoading = false;
    });
  }

  Future<void> _saveZone(String zoneCode) async {
    await PreferencesService.saveSelectedZone(zoneCode);
    setState(() {
      _selectedZone = zoneCode;
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zone saved: $zoneCode'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateNotificationSettings(bool enabled) async {
    await PreferencesService.saveNotificationsEnabled(enabled);
    setState(() {
      _notificationsEnabled = enabled;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'Notifications enabled' : 'Notifications disabled',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateAdzanSettings(bool enabled) async {
    await PreferencesService.saveAdzanEnabled(enabled);
    setState(() {
      _adzanEnabled = enabled;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'Adzan sound enabled' : 'Adzan sound disabled',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildNotificationSettings() {
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
                  Icons.notifications,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Get reminded 10 minutes before prayer time and when it\'s time to pray.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Notifications toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Prayer Time Notifications',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Receive notifications for prayer times'),
                value: _notificationsEnabled,
                onChanged: _updateNotificationSettings,
                activeColor: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 12),

            // Adzan sound toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Adzan Sound',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Play adzan sound when prayer time arrives',
                ),
                value: _adzanEnabled,
                onChanged: _updateAdzanSettings,
                activeColor: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 16),

            // Testing buttons
            const Text(
              'Testing:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Test basic notification
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.showTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notification_add),
                label: const Text('Test Basic Notification'),
              ),
            ),

            const SizedBox(height: 8),

            // Test reminder notification
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.testReminderNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test reminder sent!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.schedule),
                label: const Text('Test Prayer Reminder'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ),

            const SizedBox(height: 8),

            // Test prayer time + adzan
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.testPrayerTimeNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Test prayer time notification + adzan sent!',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.mosque),
                label: const Text('Test Prayer Time + Adzan'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
              ),
            ),

            const SizedBox(height: 8),

            // Stop audio button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.stopAudio();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio stopped!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop Audio'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),

            const SizedBox(height: 16),

            // Scheduled notifications testing section
            const Divider(),
            const Text(
              'Scheduled Notifications (New System):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Test scheduled notification for next minute
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.scheduleTestNotificationForNextMinute();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification scheduled for next minute!'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.schedule_send),
                label: const Text('Schedule Test for Next Minute'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.purple),
              ),
            ),

            const SizedBox(height: 8),

            // Debug scheduled notifications
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.debugScheduledNotifications();
                  final pending = await NotificationService.getPendingNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Found ${pending.length} scheduled notifications. Check console for details.'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug Scheduled Notifications'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSelector() {
    final zones = PrayerTimeService.getZones();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Prayer Time Zone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your location to get accurate prayer times',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedZone,
                  hint: const Text('Select Zone'),
                  items: zones.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _saveZone(newValue);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentZoneInfo() {
    final zones = PrayerTimeService.getZones();
    final zoneName = zones[_selectedZone] ?? 'Unknown Zone';

    return Card(
      elevation: 2,
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Current Zone',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedZone,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(zoneName, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentZoneInfo(),
                  const SizedBox(height: 16),
                  _buildZoneSelector(),
                  const SizedBox(height: 16),
                  _buildNotificationSettings(),
                  const SizedBox(height: 24),

                  // Weekly Schedule section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_view_week,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Prayer Schedule',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'View prayer times for the upcoming week.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WeeklyScheduleScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.table_chart),
                              label: const Text('View Weekly Schedule'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Additional settings section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Prayer times are provided by JAKIM (Jabatan Kemajuan Islam Malaysia) e-Solat API.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Data is updated in real-time.',
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
}
