import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer_time.dart';

class PrayerDetailScreen extends StatefulWidget {
  final String prayerName;
  final String prayerTime;
  final PrayerTime prayerTimeData;
  final IconData icon;
  final Color color;

  const PrayerDetailScreen({
    super.key,
    required this.prayerName,
    required this.prayerTime,
    required this.prayerTimeData,
    required this.icon,
    required this.color,
  });

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  Timer? _timer;
  Duration _countdown = Duration.zero;
  bool _isPrayerTimePassed = false;
  String _countdownText = '';
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _calculateCountdown();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateCountdown();
      }
    });
  }

  void _calculateCountdown() {
    final now = DateTime.now();
    final prayerDateTime = _getPrayerDateTime(widget.prayerTime);
    
    if (prayerDateTime.isAfter(now)) {
      // Prayer time is in the future - show countdown
      setState(() {
        _countdown = prayerDateTime.difference(now);
        _isPrayerTimePassed = false;
        _statusText = 'Time remaining until ${widget.prayerName}';
        _countdownText = _formatCountdown(_countdown);
      });
    } else {
      // Prayer time has passed - check if next prayer has started
      final nextPrayerTime = _getNextPrayerTime();
      final nextPrayerDateTime = nextPrayerTime != null ? _getPrayerDateTime(nextPrayerTime) : null;
      
      if (nextPrayerDateTime != null && now.isBefore(nextPrayerDateTime)) {
        // Current prayer time has started but next prayer hasn't - show elapsed time
        final elapsed = now.difference(prayerDateTime);
        final nextPrayerName = _getNextPrayerName();
        final timeToNextPrayer = nextPrayerDateTime.difference(now);
        
        setState(() {
          _countdown = elapsed;
          _isPrayerTimePassed = true;
          _statusText = '${widget.prayerName} is ongoing • Next: $nextPrayerName in ${_formatCountdown(timeToNextPrayer)}';
          _countdownText = _formatCountdown(elapsed);
        });
      } else if (nextPrayerDateTime != null && now.isAtSameMomentAs(nextPrayerDateTime)) {
        // Next prayer time has just started - show prayer completed
        final elapsed = now.difference(prayerDateTime);
        setState(() {
          _countdown = elapsed;
          _isPrayerTimePassed = true;
          _statusText = '${widget.prayerName} prayer time has ended';
          _countdownText = 'Next prayer has started';
        });
      } else if (nextPrayerDateTime != null && now.isAfter(nextPrayerDateTime)) {
        // Next prayer has already started - show prayer completed
        final elapsed = now.difference(prayerDateTime);
        setState(() {
          _countdown = elapsed;
          _isPrayerTimePassed = true;
          _statusText = '${widget.prayerName} prayer time has ended';
          _countdownText = 'Prayer completed';
        });
      } else {
        // This is the last prayer of the day (Isha) - show elapsed time until midnight
        final elapsed = now.difference(prayerDateTime);
        final midnight = DateTime(now.year, now.month, now.day + 1);
        final timeToMidnight = midnight.difference(now);
        
        setState(() {
          _countdown = elapsed;
          _isPrayerTimePassed = true;
          _statusText = '${widget.prayerName} is ongoing • Next: Fajr in ${_formatCountdown(timeToMidnight)}';
          _countdownText = _formatCountdown(elapsed);
        });
      }
    }
  }

  DateTime _getPrayerDateTime(String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    var prayerDateTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If the prayer time has passed today and it's before midnight, 
    // it might be for tomorrow (like Fajr)
    if (prayerDateTime.isBefore(now) && widget.prayerName == 'Fajr') {
      prayerDateTime = prayerDateTime.add(const Duration(days: 1));
    }
    
    return prayerDateTime;
  }

  String? _getNextPrayerTime() {
    final prayers = [
      {'name': 'Fajr', 'time': widget.prayerTimeData.fajr},
      {'name': 'Syuruk', 'time': widget.prayerTimeData.syuruk},
      {'name': 'Dhuhr', 'time': widget.prayerTimeData.dhuhr},
      {'name': 'Asr', 'time': widget.prayerTimeData.asr},
      {'name': 'Maghrib', 'time': widget.prayerTimeData.maghrib},
      {'name': 'Isha', 'time': widget.prayerTimeData.isha},
    ];

    // Find current prayer index
    int currentIndex = prayers.indexWhere((prayer) => prayer['name'] == widget.prayerName);
    
    // Return next prayer time, or null if this is the last prayer
    if (currentIndex >= 0 && currentIndex < prayers.length - 1) {
      return prayers[currentIndex + 1]['time'] as String;
    }
    
    return null;
  }

  String? _getNextPrayerName() {
    final prayers = [
      {'name': 'Fajr', 'time': widget.prayerTimeData.fajr},
      {'name': 'Syuruk', 'time': widget.prayerTimeData.syuruk},
      {'name': 'Dhuhr', 'time': widget.prayerTimeData.dhuhr},
      {'name': 'Asr', 'time': widget.prayerTimeData.asr},
      {'name': 'Maghrib', 'time': widget.prayerTimeData.maghrib},
      {'name': 'Isha', 'time': widget.prayerTimeData.isha},
    ];

    // Find current prayer index
    int currentIndex = prayers.indexWhere((prayer) => prayer['name'] == widget.prayerName);
    
    // Return next prayer name, or null if this is the last prayer
    if (currentIndex >= 0 && currentIndex < prayers.length - 1) {
      return prayers[currentIndex + 1]['name'] as String;
    }
    
    return null;
  }

  String _formatCountdown(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h ${duration.inMinutes.remainder(60)}m ${duration.inSeconds.remainder(60)}s';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m ${duration.inSeconds.remainder(60)}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatTime(String time) {
    if (time == '00:00:00') return '-';
    
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
        title: Text('${widget.prayerName} Prayer'),
        backgroundColor: widget.color.withOpacity(0.1),
        foregroundColor: widget.color,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.color.withOpacity(0.1),
              widget.color.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Prayer Info Card
                Card(
                  elevation: 8,
                  shadowColor: widget.color.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.color.withOpacity(0.1),
                          widget.color.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          widget.icon,
                          size: 70,
                          color: widget.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.prayerName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(widget.prayerTime),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[700],
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Countdown Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _isPrayerTimePassed 
                                ? Colors.orange.withOpacity(0.1)
                                : widget.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isPrayerTimePassed 
                                  ? Colors.orange.withOpacity(0.3)
                                  : widget.color.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _countdownText,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _isPrayerTimePassed 
                                  ? Colors.orange[700]
                                  : widget.color,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Prayer Info
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: widget.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Date Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Gregorian', '${widget.prayerTimeData.day}, ${widget.prayerTimeData.date}'),
                        _buildInfoRow('Hijri', widget.prayerTimeData.hijri),
                        _buildInfoRow('Current Time', DateFormat('HH:mm:ss').format(DateTime.now())),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isPrayerTimePassed 
                        ? (_statusText.contains('ongoing') 
                            ? Colors.green.withOpacity(0.2) 
                            : Colors.orange.withOpacity(0.2))
                        : widget.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPrayerTimePassed 
                            ? (_statusText.contains('ongoing') 
                                ? Icons.play_circle_filled 
                                : Icons.check_circle)
                            : Icons.timer,
                        size: 16,
                        color: _isPrayerTimePassed 
                            ? (_statusText.contains('ongoing') 
                                ? Colors.green[700] 
                                : Colors.orange[700])
                            : widget.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPrayerTimePassed 
                            ? (_statusText.contains('ongoing') ? 'ACTIVE' : 'ENDED')
                            : 'UPCOMING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _isPrayerTimePassed 
                              ? (_statusText.contains('ongoing') 
                                  ? Colors.green[700] 
                                  : Colors.orange[700])
                              : widget.color,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24), // Add bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
