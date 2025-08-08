import 'package:flutter/material.dart';
import '../models/prayer_time.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';

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
        setState(() {
          _error = 'No cached data available for the upcoming week.\nPlease refresh the main prayer times screen to fetch new data.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading weekly schedule: $e';
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
                  'Cached Data Range',
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
              'Zone: $_selectedZone',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              'From: ${_dataRange!['start_date']}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              'To: ${_dataRange!['end_date']}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTable() {
    if (_weeklyPrayerTimes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_view_week,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next 7 Days Prayer Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 50,
                dataRowMaxHeight: 60,
                columnSpacing: 20,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 11,
                ),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Day')),
                  DataColumn(label: Text('Fajr')),
                  DataColumn(label: Text('Syuruk')),
                  DataColumn(label: Text('Dhuhr')),
                  DataColumn(label: Text('Asr')),
                  DataColumn(label: Text('Maghrib')),
                  DataColumn(label: Text('Isha')),
                ],
                rows: _weeklyPrayerTimes.map((prayerTime) {
                  final isToday = _isToday(prayerTime.date);
                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (isToday) {
                          return Theme.of(context).primaryColor.withOpacity(0.1);
                        }
                        return null;
                      },
                    ),
                    cells: [
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDisplayDate(prayerTime.date),
                              style: TextStyle(
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? Theme.of(context).primaryColor : null,
                              ),
                            ),
                            Text(
                              prayerTime.hijri,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                                fontWeight: isToday ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          _getShortDay(prayerTime.day),
                          style: TextStyle(
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                      ),
                      DataCell(_buildTimeCell(prayerTime.fajr, isToday)),
                      DataCell(_buildTimeCell(prayerTime.syuruk, isToday)),
                      DataCell(_buildTimeCell(prayerTime.dhuhr, isToday)),
                      DataCell(_buildTimeCell(prayerTime.asr, isToday)),
                      DataCell(_buildTimeCell(prayerTime.maghrib, isToday)),
                      DataCell(_buildTimeCell(prayerTime.isha, isToday)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCell(String time, bool isToday) {
    return Text(
      _formatTime(time),
      style: TextStyle(
        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        color: isToday ? Theme.of(context).primaryColor : null,
      ),
    );
  }

  bool _isToday(String date) {
    final today = DateTime.now();
    final todayStr = _formatDateForDatabase(today);
    return date == todayStr;
  }

  String _formatDisplayDate(String dbDate) {
    // Convert from "DD-MMM-YYYY" to "DD/MM"
    try {
      final parts = dbDate.split('-');
      if (parts.length == 3) {
        return '${parts[0]}/${_getMonthNumber(parts[1]).toString().padLeft(2, '0')}';
      }
      return dbDate;
    } catch (e) {
      return dbDate;
    }
  }

  int _getMonthNumber(String monthAbbr) {
    const monthMap = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    return monthMap[monthAbbr] ?? 1;
  }

  String _getShortDay(String day) {
    const dayMap = {
      'Monday': 'Mon',
      'Tuesday': 'Tue', 
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun'
    };
    return dayMap[day] ?? day;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Prayer Schedule'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeeklySchedule,
            tooltip: 'Refresh',
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
                          child: const Text('Try Again'),
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
                      _buildWeeklyTable(),
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
                                  'Today\'s row is highlighted. Data is from cached offline storage.',
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
