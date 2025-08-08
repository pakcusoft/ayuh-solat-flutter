import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prayer_time.dart';
import '../services/prayer_time_service.dart';
import '../services/preferences_service.dart';
import '../services/widget_service.dart';
import 'settings_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> with WidgetsBindingObserver {
  PrayerTimeResponse? _prayerTimeResponse;
  bool _isLoading = true;
  String _selectedZone = 'WLY01';
  String? _error;
  Timer? _midnightTimer;
  DateTime? _lastRefreshDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadZoneAndFetchPrayerTimes();
    _setupMidnightTimer();
    _setupWeeklyCacheUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
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
      
      final response = await PrayerTimeService.fetchPrayerTimes(zone: _selectedZone);
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
      final lastRefreshDay = DateTime(_lastRefreshDate!.year, _lastRefreshDate!.month, _lastRefreshDate!.day);
      final currentDay = DateTime(now.year, now.month, now.day);
      
      if (currentDay.isAfter(lastRefreshDay)) {
        // It's a new day, refresh prayer times
        _fetchPrayerTimes();
        print('Detected new day, refreshing prayer times');
      }
    }
  }

  Widget _buildPrayerTimeCard(String prayerName, String time, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              prayerName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
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

  String _decodeBearing(String bearing) {
    // Decode HTML entities in the bearing string
    return bearing
        .replaceAll('&deg;', '°')     // degree symbol
        .replaceAll('&#176;', '°')    // degree symbol
        .replaceAll('&prime;', '′')   // prime symbol (minutes)
        .replaceAll('&#8242;', '′')   // prime symbol (minutes)
        .replaceAll('&Prime;', '″')   // double prime (seconds)
        .replaceAll('&#8243;', '″');  // double prime (seconds)
  }

  Future<void> _navigateToSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    // Reload prayer times when returning from settings in case zone changed
    _loadZoneAndFetchPrayerTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPrayerTimes,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _prayerTimeResponse == null || _prayerTimeResponse!.prayerTimes.isEmpty
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
                                ? 'No data available for this zone'
                                : 'No prayer times available',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          if (_prayerTimeResponse?.status == 'NO_RECORD!')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Please change your zone in settings',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _navigateToSettings,
                            child: const Text('Open Settings'),
                          ),
                        ],
                      ),
                    )
                  : _buildPrayerTimesContent(),
    );
  }

  Widget _buildPrayerTimesContent() {
    final prayerTime = _prayerTimeResponse!.prayerTimes.first;
    
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
                    '${prayerTime.day}, ${prayerTime.date}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Hijri: ${prayerTime.hijri}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zone: ${_prayerTimeResponse!.zone}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Qibla Direction: ${_decodeBearing(_prayerTimeResponse!.bearing)}',
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
              _buildPrayerTimeCard('Fajr', prayerTime.fajr, Icons.brightness_2, Colors.blue),
              _buildPrayerTimeCard('Syuruk', prayerTime.syuruk, Icons.wb_sunny, Colors.orange),
              _buildPrayerTimeCard('Dhuhr', prayerTime.dhuhr, Icons.wb_sunny, Colors.yellow[700]!),
              _buildPrayerTimeCard('Asr', prayerTime.asr, Icons.wb_twilight, Colors.orange[800]!),
              _buildPrayerTimeCard('Maghrib', prayerTime.maghrib, Icons.brightness_3, Colors.deepOrange),
              _buildPrayerTimeCard('Isha', prayerTime.isha, Icons.nights_stay, Colors.purple),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Server Time and Status
          Column(
            children: [
              Center(
                child: Text(
                  'Last updated: ${_prayerTimeResponse!.serverTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (_prayerTimeResponse!.status.contains('Cached'))
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        'Offline Mode',
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
