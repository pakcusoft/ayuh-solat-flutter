import 'dart:async';
import 'package:flutter/material.dart';
import '../localization/app_localization.dart';
import '../models/prayer_time.dart';
import '../services/prayer_time_service.dart';
import '../services/preferences_service.dart';
import '../services/widget_service.dart';
import 'settings_screen.dart';
import 'prayer_detail_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with WidgetsBindingObserver {
  PrayerTimeResponse? _prayerTimeResponse;
  bool _isLoading = true;
  String _selectedZone = 'WLY01';
  String? _error;
  Timer? _midnightTimer;
  DateTime? _lastRefreshDate;
  Timer? _currentTimeTimer;
  String? _currentPrayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadZoneAndFetchPrayerTimes();
    _setupMidnightTimer();
    _setupWeeklyCacheUpdate();
    _startCurrentTimeTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _currentTimeTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check for date change when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkForDateChange();
    }
  }

  Future<void> _loadZoneAndFetchPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load saved zone from preferences
      final savedZone = await PreferencesService.getSelectedZone();
      setState(() {
        _selectedZone = savedZone;
      });

      // Fetch prayer times for the saved zone
      await _fetchPrayerTimes();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading preferences: $e';
      });
    }
  }

  Future<void> _fetchPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check and update cache in background
      PrayerTimeService.checkAndUpdateCache(_selectedZone);

      final response = await PrayerTimeService.fetchPrayerTimes(
        zone: _selectedZone,
      );
      setState(() {
        _prayerTimeResponse = response;
        _isLoading = false;
        _lastRefreshDate = DateTime.now(); // Track when we last refreshed
        if (response == null) {
          _error = 'Failed to load prayer times';
        }
      });

      // Update widget after successful prayer times fetch
      if (response != null) {
        WidgetService.updateWidget();
        // Update current prayer highlighting after data is loaded
        _updateCurrentPrayer();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  void _setupWeeklyCacheUpdate() {
    // Set up weekly timer to update cache
    Timer.periodic(const Duration(days: 1), (timer) {
      if (mounted) {
        // Check and update cache daily (the service will decide if update is needed)
        PrayerTimeService.checkAndUpdateCache(_selectedZone);
      }
    });
  }

  void _setupMidnightTimer() {
    // Calculate seconds until next midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final secondsUntilMidnight = tomorrow.difference(now).inSeconds;

    // Set initial timer to trigger at midnight
    _midnightTimer = Timer(Duration(seconds: secondsUntilMidnight), () {
      // Refresh prayer times at midnight
      if (mounted) {
        _fetchPrayerTimes();
        print('Auto-refreshed prayer times at midnight');
      }

      // Set up recurring daily timer
      _setDailyTimer();
    });
  }

  void _setDailyTimer() {
    // Cancel existing timer
    _midnightTimer?.cancel();

    // Set up daily recurring timer (every 24 hours)
    _midnightTimer = Timer.periodic(const Duration(days: 1), (timer) {
      if (mounted) {
        _fetchPrayerTimes();
        print('Auto-refreshed prayer times at midnight');
      }
    });
  }

  void _checkForDateChange() {
    // Check if we need to refresh because it's a new day
    if (_lastRefreshDate != null) {
      final now = DateTime.now();
      final lastRefreshDay = DateTime(
        _lastRefreshDate!.year,
        _lastRefreshDate!.month,
        _lastRefreshDate!.day,
      );
      final currentDay = DateTime(now.year, now.month, now.day);

      if (currentDay.isAfter(lastRefreshDay)) {
        // It's a new day, refresh prayer times
        _fetchPrayerTimes();
        print('Detected new day, refreshing prayer times');
      }
    }
  }

  void _startCurrentTimeTimer() {
    // Start the timer first
    _currentTimeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _updateCurrentPrayer();
      }
    });
    // Initial update will be called after data is loaded in _fetchPrayerTimes
  }

  void _updateCurrentPrayer() {
    if (_prayerTimeResponse == null || _prayerTimeResponse!.prayerTimes.isEmpty)
      return;

    final prayerTime = _prayerTimeResponse!.prayerTimes.first;
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Use the same logic as widget service
    final prayers = [
      {'name': 'Fajr', 'time': _formatTime(prayerTime.fajr)},
      {'name': 'Dhuhr', 'time': _formatTime(prayerTime.dhuhr)},
      {'name': 'Asr', 'time': _formatTime(prayerTime.asr)},
      {'name': 'Maghrib', 'time': _formatTime(prayerTime.maghrib)},
      {'name': 'Isha', 'time': _formatTime(prayerTime.isha)},
    ];

    String currentPrayer = '';
    
    // Find current active prayer (most recent prayer that has passed)
    // This logic matches exactly with WidgetService._findCurrentPrayer
    for (int i = 0; i < prayers.length; i++) {
      final prayerTimeStr = prayers[i]['time']!;
      final prayerName = prayers[i]['name']!;
      
      // Check if current time is after this prayer time
      if (_compareTime(currentTime, prayerTimeStr) >= 0) {
        currentPrayer = prayerName;
        
        // Special case for Fajr: if Syuruk has passed, Fajr is no longer current
        if (prayerName == 'Fajr' && _compareTime(currentTime, _formatTime(prayerTime.syuruk)) >= 0) {
          currentPrayer = '';
        }
      }
    }

    if (currentPrayer != _currentPrayer) {
      setState(() {
        _currentPrayer = currentPrayer;
      });
      print('Current prayer updated to: $currentPrayer at ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
      
      // Debug info to help troubleshoot prayer time detection
      final fajrTime = _parseTimeOnly(prayerTime.fajr);
      final syurukTime = _parseTimeOnly(prayerTime.syuruk);
      final dhuhrTime = _parseTimeOnly(prayerTime.dhuhr);
      final asrTime = _parseTimeOnly(prayerTime.asr);
      final maghribTime = _parseTimeOnly(prayerTime.maghrib);
      final ishaTime = _parseTimeOnly(prayerTime.isha);
      
      print('Prayer times today:');
      print('  Fajr: ${_formatTime(prayerTime.fajr)} (${fajrTime?.hour}:${fajrTime?.minute.toString().padLeft(2, '0')})');
      print('  Syuruk: ${_formatTime(prayerTime.syuruk)} (${syurukTime?.hour}:${syurukTime?.minute.toString().padLeft(2, '0')})');
      print('  Dhuhr: ${_formatTime(prayerTime.dhuhr)} (${dhuhrTime?.hour}:${dhuhrTime?.minute.toString().padLeft(2, '0')})');
      print('  Asr: ${_formatTime(prayerTime.asr)} (${asrTime?.hour}:${asrTime?.minute.toString().padLeft(2, '0')})');
      print('  Maghrib: ${_formatTime(prayerTime.maghrib)} (${maghribTime?.hour}:${maghribTime?.minute.toString().padLeft(2, '0')})');
      print('  Isha: ${_formatTime(prayerTime.isha)} (${ishaTime?.hour}:${ishaTime?.minute.toString().padLeft(2, '0')})');
      print('  Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    }
  }

  // Helper method to get English prayer name from localized name
  String _getEnglishPrayerName(String localizedName) {
    final l10n = AppLocalization.of(context);
    if (localizedName == l10n.fajr) return 'Fajr';
    if (localizedName == l10n.dhuhr) return 'Dhuhr';
    if (localizedName == l10n.asr) return 'Asr';
    if (localizedName == l10n.maghrib) return 'Maghrib';
    if (localizedName == l10n.isha) return 'Isha';
    return localizedName; // fallback
  }

  DateTime? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } catch (e) {
      // Handle parsing error
    }
    return null;
  }

  DateTime? _parsePrayerTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final now = DateTime.now();
        var prayerDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        // Handle Fajr prayer which might be tomorrow if it already passed today
        if (prayerDateTime.isBefore(now) &&
            timeString == _prayerTimeResponse!.prayerTimes.first.fajr) {
          prayerDateTime = prayerDateTime.add(const Duration(days: 1));
        }

        return prayerDateTime;
      }
    } catch (e) {
      // Handle parsing error
    }
    return null;
  }

  DateTime? _parseTimeOnly(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final now = DateTime.now();
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } catch (e) {
      // Handle parsing error
      print('Error parsing time: $timeString - $e');
    }
    return null;
  }

  Widget _buildPrayerTimeCard(
    String prayerName,
    String time,
    IconData icon,
    Color color,
  ) {
    final l10n = AppLocalization.of(context);
    // Convert localized prayer name to English for comparison
    final englishPrayerName = _getEnglishPrayerName(prayerName);
    final isCurrentPrayer = _currentPrayer == englishPrayerName;

    return GestureDetector(
      onTap: () {
        if (_prayerTimeResponse != null &&
            _prayerTimeResponse!.prayerTimes.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrayerDetailScreen(
                prayerName: prayerName,
                prayerTime: time,
                prayerTimeData: _prayerTimeResponse!.prayerTimes.first,
                icon: icon,
                color: color,
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: isCurrentPrayer ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isCurrentPrayer
              ? BorderSide(color: color, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: isCurrentPrayer
                  ? [color.withOpacity(0.2), color.withOpacity(0.1)]
                  : [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(icon, size: 28, color: color),
                  if (isCurrentPrayer)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                prayerName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrentPrayer ? color : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              if (isCurrentPrayer)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.currentPrayer,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    // Convert from "HH:MM:SS" to "HH:MM"
    // Also handle special cases like "00:00:00" (for dhuha which is typically not used)
    if (time == '00:00:00') {
      return '-';
    }

    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  // Compare two time strings in HH:MM format
  int _compareTime(String time1, String time2) {
    final parts1 = time1.split(':');
    final parts2 = time2.split(':');
    
    final hour1 = int.parse(parts1[0]);
    final minute1 = int.parse(parts1[1]);
    final hour2 = int.parse(parts2[0]);
    final minute2 = int.parse(parts2[1]);
    
    final totalMinutes1 = hour1 * 60 + minute1;
    final totalMinutes2 = hour2 * 60 + minute2;
    
    return totalMinutes1.compareTo(totalMinutes2);
  }

  String _decodeBearing(String bearing) {
    // Decode HTML entities in the bearing string
    return bearing
        .replaceAll('&deg;', '°') // degree symbol
        .replaceAll('&#176;', '°') // degree symbol
        .replaceAll('&prime;', '′') // prime symbol (minutes)
        .replaceAll('&#8242;', '′') // prime symbol (minutes)
        .replaceAll('&Prime;', '″') // double prime (seconds)
        .replaceAll('&#8243;', '″'); // double prime (seconds)
  }

  String _getZoneName(String zone) {
    final zones = PrayerTimeService.getZones();
    return zones[zone] ?? 'Unknown Zone';
  }

  Future<void> _navigateToSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
    // Reload prayer times when returning from settings in case zone changed
    _loadZoneAndFetchPrayerTimes();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPrayerTimes,
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: Text(l10n.loading))
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadZoneAndFetchPrayerTimes,
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ),
            )
          : _prayerTimeResponse == null ||
                _prayerTimeResponse!.prayerTimes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _prayerTimeResponse?.status == 'NO_RECORD!'
                        ? Icons.location_off
                        : Icons.schedule,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _prayerTimeResponse?.status == 'NO_RECORD!'
                        ? l10n.noDataAvailable
                        : l10n.noPrayerTimes,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_prayerTimeResponse?.status == 'NO_RECORD!')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        l10n.pleaseChangeZone,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _navigateToSettings,
                    child: Text(l10n.openSettings),
                  ),
                ],
              ),
            )
          : _buildPrayerTimesContent(),
    );
  }

  Widget _buildPrayerTimesContent() {
    final prayerTime = _prayerTimeResponse!.prayerTimes.first;
    final l10n = AppLocalization.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Zone Info
          Card(
            elevation: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.getLocalizedDayName(prayerTime.day)}, ${prayerTime.date}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${l10n.hijriLabel}: ${prayerTime.hijri}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getZoneName(_prayerTimeResponse!.zone),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${l10n.qiblaDirection}: ${_decodeBearing(_prayerTimeResponse!.bearing)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Prayer Times Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildPrayerTimeCard(
                l10n.fajr,
                prayerTime.fajr,
                Icons.brightness_2,
                Colors.blue,
              ),
              _buildPrayerTimeCard(
                l10n.syuruk,
                prayerTime.syuruk,
                Icons.wb_sunny,
                Colors.orange,
              ),
              _buildPrayerTimeCard(
                l10n.dhuhr,
                prayerTime.dhuhr,
                Icons.wb_sunny,
                Colors.yellow[700]!,
              ),
              _buildPrayerTimeCard(
                l10n.asr,
                prayerTime.asr,
                Icons.wb_twilight,
                Colors.orange[800]!,
              ),
              _buildPrayerTimeCard(
                l10n.maghrib,
                prayerTime.maghrib,
                Icons.brightness_3,
                Colors.deepOrange,
              ),
              _buildPrayerTimeCard(
                l10n.isha,
                prayerTime.isha,
                Icons.nights_stay,
                Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Server Time and Status
          Column(
            children: [
              Center(
                child: Text(
                  l10n.lastUpdated(_prayerTimeResponse!.serverTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              if (_prayerTimeResponse!.status.contains('Cached'))
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.offline_bolt,
                        size: 12,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.offlineMode,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
