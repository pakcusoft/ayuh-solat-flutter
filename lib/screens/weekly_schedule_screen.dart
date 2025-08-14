import 'package:flutter/material.dart';
import '../models/prayer_time.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../localization/app_localization.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  List<PrayerTime> _weeklyPrayerTimes = [];
  bool _isLoading = true;
  String? _error;
  String _selectedZone = 'WLY01';
  Map<String, String>? _dataRange;

  @override
  void initState() {
    super.initState();
    _loadWeeklySchedule();
  }

  Future<void> _loadWeeklySchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current zone
      final zone = await PreferencesService.getSelectedZone();
      setState(() {
        _selectedZone = zone;
      });

      // Get data range info
      final dataRange = await DatabaseService.getDataRange(zone);
      setState(() {
        _dataRange = dataRange;
      });

      // Get prayer times for the next 7 days
      final now = DateTime.now();
      final weeklyTimes = <PrayerTime>[];
      
      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = _formatDateForDatabase(date);
        final prayerTime = await DatabaseService.getPrayerTimeForDate(zone, dateStr);
        
        if (prayerTime != null) {
          weeklyTimes.add(prayerTime);
        }
      }

      setState(() {
        _weeklyPrayerTimes = weeklyTimes;
        _isLoading = false;
      });

      if (weeklyTimes.isEmpty) {
        final l10n = AppLocalization(Locale('ms')); // Use default for error state
        setState(() {
          _error = l10n.noCachedDataWeek;
        });
      }
    } catch (e) {
      final l10n = AppLocalization(Locale('ms')); // Use default for error state
      setState(() {
        _isLoading = false;
        _error = l10n.errorLoadingWeekly(e.toString());
      });
    }
  }

  String _formatDateForDatabase(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }

  Widget _buildDataRangeInfo() {
    if (_dataRange == null) return const SizedBox.shrink();
    
    final l10n = AppLocalization.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.cachedDataRange,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.zone}: $_selectedZone',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${l10n.from}: ${_dataRange!['start_date']}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              '${l10n.to}: ${_dataRange!['end_date']}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTables() {
    if (_weeklyPrayerTimes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final l10n = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.nextSevenDays,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Individual day cards
        ..._weeklyPrayerTimes.map((prayerTime) => _buildDayCard(prayerTime)),
      ],
    );
  }

  Widget _buildDayCard(PrayerTime prayerTime) {
    final isToday = _isToday(prayerTime.date);
    
    return Card(
      elevation: isToday ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: isToday 
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isToday 
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isToday)
                          Icon(
                            Icons.today,
                            size: 16,
                            color: Colors.white,
                          ),
                        if (isToday) const SizedBox(width: 4),
                        Text(
                          '${_getFullDay(prayerTime.day)}, ${_formatFullDisplayDate(prayerTime.date)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isToday ? Colors.white : Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    prayerTime.hijri,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Prayer times grid
              _buildPrayerTimesGrid(prayerTime, isToday),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesGrid(PrayerTime prayerTime, bool isToday) {
    final l10n = AppLocalization.of(context);
    final prayerData = [
      {'name': l10n.fajr, 'time': prayerTime.fajr, 'icon': Icons.brightness_2},
      {'name': l10n.syuruk, 'time': prayerTime.syuruk, 'icon': Icons.wb_sunny},
      {'name': l10n.dhuhr, 'time': prayerTime.dhuhr, 'icon': Icons.wb_sunny_outlined},
      {'name': l10n.asr, 'time': prayerTime.asr, 'icon': Icons.brightness_6},
      {'name': l10n.maghrib, 'time': prayerTime.maghrib, 'icon': Icons.brightness_4},
      {'name': l10n.isha, 'time': prayerTime.isha, 'icon': Icons.brightness_2_outlined},
    ];

    return Column(
      children: [
        // First row: Fajr, Syuruk, Dhuhr
        Row(
          children: prayerData.take(3).map((prayer) => 
            Expanded(child: _buildPrayerTimeItem(prayer, isToday))
          ).toList(),
        ),
        const SizedBox(height: 8),
        // Second row: Asr, Maghrib, Isha
        Row(
          children: prayerData.skip(3).map((prayer) => 
            Expanded(child: _buildPrayerTimeItem(prayer, isToday))
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildPrayerTimeItem(Map<String, dynamic> prayer, bool isToday) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isToday 
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            prayer['icon'] as IconData,
            size: 20,
            color: isToday 
                ? Theme.of(context).primaryColor
                : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            prayer['name'] as String,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isToday 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(prayer['time'] as String),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isToday 
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(String date) {
    final today = DateTime.now();
    final todayStr = _formatDateForDatabase(today);
    return date == todayStr;
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

  String _getFullDay(String day) {
    final l10n = AppLocalization.of(context);
    return l10n.getDayName(day);
  }

  String _formatFullDisplayDate(String dbDate) {
    // Convert from "DD-MMM-YYYY" to "DD MMM YYYY" with localized month
    try {
      final parts = dbDate.split('-');
      if (parts.length == 3) {
        final l10n = AppLocalization.of(context);
        final localizedMonth = l10n.getMonthAbbreviation(parts[1]);
        return '${parts[0]} $localizedMonth ${parts[2]}';
      }
      return dbDate;
    } catch (e) {
      return dbDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyPrayerSchedule),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeeklySchedule,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadWeeklySchedule,
                          child: Text(l10n.tryAgain),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataRangeInfo(),
                      _buildWeeklyTables(),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.todayHighlightInfo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
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
