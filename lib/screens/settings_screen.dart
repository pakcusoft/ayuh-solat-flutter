import 'package:flutter/material.dart';
import '../localization/app_localization.dart';
import '../services/prayer_time_service.dart';
import '../services/preferences_service.dart';
import '../services/language_service.dart';
import '../main.dart';
import 'weekly_schedule_screen.dart';
import 'testing_screen.dart';
import 'zone_selection_screen.dart';

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

  Future<void> _saveZone(String zoneCode, AppLocalization l10n) async {
    await PreferencesService.saveSelectedZone(zoneCode);
    setState(() {
      _selectedZone = zoneCode;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.zoneSaved(zoneCode)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateNotificationSettings(bool enabled, AppLocalization l10n) async {
    await PreferencesService.saveNotificationsEnabled(enabled);
    setState(() {
      _notificationsEnabled = enabled;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? l10n.notificationsEnabled : l10n.notificationsDisabled,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateAdzanSettings(bool enabled, AppLocalization l10n) async {
    await PreferencesService.saveAdzanEnabled(enabled);
    setState(() {
      _adzanEnabled = enabled;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? l10n.adzanEnabled : l10n.adzanDisabled,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateLanguageSettings(String languageCode, AppLocalization l10n) async {
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
          content: Text(l10n.languageSaved(languageName)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLanguageSelector(AppLocalization l10n) {
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
                      _updateLanguageSettings(newValue, l10n);
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

  Widget _buildNotificationSettings(AppLocalization l10n) {
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
                Text(
                  l10n.notifications,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notificationsSubtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Notifications toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                title: Text(
                  l10n.prayerTimeNotifications,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(l10n.receiveNotifications),
                value: _notificationsEnabled,
                onChanged: (value) => _updateNotificationSettings(value, l10n),
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
                title: Text(
                  l10n.adzanSound,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  l10n.playAdzanSound,
                ),
                value: _adzanEnabled,
                onChanged: (value) => _updateAdzanSettings(value, l10n),
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSelector(AppLocalization l10n) {
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
                Text(
                  l10n.prayerTimeZone,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.selectLocation,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final selectedZone = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (context) => ZoneSelectionScreen(
                        currentZone: _selectedZone,
                      ),
                    ),
                  );
                  
                  if (selectedZone != null && selectedZone != _selectedZone) {
                    await _saveZone(selectedZone, l10n);
                  }
                },
                icon: const Icon(Icons.search),
                label: Text(l10n.selectZone),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentZoneInfo(AppLocalization l10n) {
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
                Text(
                  l10n.currentZone,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final l10n = AppLocalization.of(context);
    
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
                  _buildCurrentZoneInfo(l10n),
                  const SizedBox(height: 16),
                  _buildLanguageSelector(l10n),
                  const SizedBox(height: 16),
                  _buildZoneSelector(l10n),
                  const SizedBox(height: 16),
                  _buildNotificationSettings(l10n),
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
                              Text(
                                l10n.prayerSchedule,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.viewWeeklySchedule,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                              label: Text(l10n.viewWeeklyScheduleButton),
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
                              Text(
                                l10n.about,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.aboutText,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.dataUpdated,
                            style: const TextStyle(fontSize: 14),
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
