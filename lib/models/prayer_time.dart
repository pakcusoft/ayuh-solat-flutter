class PrayerTime {
  final String hijri;
  final String date;
  final String day;
  final String imsak;
  final String fajr;
  final String syuruk;
  final String dhuha;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTime({
    required this.hijri,
    required this.date,
    required this.day,
    required this.imsak,
    required this.fajr,
    required this.syuruk,
    required this.dhuha,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      hijri: json['hijri'] ?? '',
      date: json['date'] ?? '',
      day: json['day'] ?? '',
      imsak: json['imsak'] ?? '',
      fajr: json['fajr'] ?? '',
      syuruk: json['syuruk'] ?? '',
      dhuha: json['dhuha'] ?? '',
      dhuhr: json['dhuhr'] ?? '',
      asr: json['asr'] ?? '',
      maghrib: json['maghrib'] ?? '',
      isha: json['isha'] ?? '',
    );
  }
}

class PrayerTimeResponse {
  final List<PrayerTime> prayerTimes;
  final String status;
  final String serverTime;
  final String periodType;
  final String language;
  final String zone;
  final String bearing;

  PrayerTimeResponse({
    required this.prayerTimes,
    required this.status,
    required this.serverTime,
    required this.periodType,
    required this.language,
    required this.zone,
    required this.bearing,
  });

  factory PrayerTimeResponse.fromJson(Map<String, dynamic> json) {
    List<PrayerTime> prayerTimesList = [];
    
    // Handle the prayerTime field which can be:
    // - Success: a list of prayer time objects
    // - No record: an object with "data" key containing error message
    if (json['prayerTime'] != null) {
      final prayerTimeData = json['prayerTime'];
      if (prayerTimeData is List) {
        // Success case: list of prayer times
        prayerTimesList = prayerTimeData
            .map((e) => PrayerTime.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (prayerTimeData is Map<String, dynamic>) {
        // No record case: object with "data" key - leave list empty
        // The status will indicate "NO_RECORD!" in this case
      }
    }
    
    return PrayerTimeResponse(
      prayerTimes: prayerTimesList,
      status: json['status']?.toString() ?? '',
      serverTime: json['serverTime']?.toString() ?? '',
      periodType: json['periodType']?.toString() ?? '',
      language: json['lang']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      bearing: json['bearing']?.toString() ?? '',
    );
  }
}
