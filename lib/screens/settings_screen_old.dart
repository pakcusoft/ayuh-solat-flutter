import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/prayer_time_service.dart';
import '../services/preferences_service.dart';
import '../services/language_service.dart';
import '../main.dart';
import 'weekly_schedule_screen.dart';
import 'testing_screen.dart';

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
  String _selectedLanguage = 'ms';

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
    final selectedLanguage = await LanguageService.getSelectedLanguage();

    setState(() {
      _selectedZone = savedZone;
      _notificationsEnabled = notificationsEnabled;
      _adzanEnabled = adzanEnabled;
      _selectedLanguage = selectedLanguage;
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

  Future<void> _updateLanguageSettings(String languageCode) async {
    await LanguageService.saveSelectedLanguage(languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });

    // Update app locale
    final localeProvider = LocaleProvider.of(context);
    if (localeProvider != null) {
      localeProvider.setLocale(LanguageService.getLocale(languageCode));
    }

    if (mounted) {
      final languageName = LanguageService.getLanguageName(languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language saved: $languageName'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLanguageSelector(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.language,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.languageSubtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                  value: _selectedLanguage,
                  items: [
                    DropdownMenuItem<String>(
                      value: 'ms',
                      child: Text(l10n.bahasa),
                    ),
                    DropdownMenuItem<String>(
                      value: 'en',
                      child: Text(l10n.english),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _updateLanguageSettings(newValue);
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'testing') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TestingScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'testing',
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(l10n.notificationTesting),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: Text(l10n.loading))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentZoneInfo(),
                  const SizedBox(height: 16),
                  _buildLanguageSelector(),
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
