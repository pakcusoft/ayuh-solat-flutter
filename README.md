# Ayuh Solat - Malaysian Prayer Times App

A Flutter application that displays Islamic prayer times for Malaysian zones using the official JAKIM e-Solat API.

## Features

- ✅ Display today's prayer times (Fajr, Syuruk, Dhuhr, Asr, Maghrib, Isha)
- ✅ Support for all official Malaysian prayer time zones
- ✅ Beautiful Material Design 3 UI
- ✅ Separate settings page for zone selection
- ✅ Persistent zone preferences (saves selected zone)
- ✅ **Auto-refresh after midnight** (automatically updates for new day)
- ✅ **App lifecycle detection** (refreshes when returning from background)
- ✅ Qibla direction information with proper symbols (°′″)
- ✅ Hijri and Gregorian date display
- ✅ Real-time data from JAKIM e-Solat API
- ✅ Error handling for zones without data
- ✅ Responsive design that works on web, mobile, and desktop

## API Source

This app uses the official **JAKIM e-Solat API**:
- Base URL: `https://www.e-solat.gov.my/index.php`
- Endpoint: `r=esolatApi/takwimsolat`
- Parameters: `period=today&zone={ZONE_CODE}`

## Supported Zones

The app includes all official Malaysian prayer time zones:

### States and Federal Territories
- **Johor** (JHR01-JHR04)
- **Kedah** (KDH01-KDH07)
- **Kelantan** (KTN01-KTN02)
- **Melaka** (MLK01)
- **Negeri Sembilan** (NGS01-NGS03)
- **Pahang** (PHG01-PHG07)
- **Perlis** (PLS01)
- **Pulau Pinang** (PNG01)
- **Perak** (PRK01-PRK07)
- **Sabah** (SBH01-SBH09)
- **Selangor** (SGR01-SGR03)
- **Sarawak** (SWK01-SWK09)
- **Terengganu** (TRG01-TRG04)
- **Wilayah Persekutuan** (WLY01-WLY02)
  - WLY01: Kuala Lumpur, Putrajaya
  - WLY02: Labuan

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Chrome (for web testing)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ayuhsolat
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For web
flutter run -d chrome

# For mobile (with device connected)
flutter run

# For desktop
flutter run -d macos  # or windows/linux
```

## Dependencies

- **http**: ^1.1.0 - For API calls
- **intl**: ^0.19.0 - For date formatting
- **shared_preferences**: ^2.2.2 - For persistent storage
- **cupertino_icons**: ^1.0.8 - iOS style icons
- **flutter_lints**: ^5.0.0 - Code quality

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── prayer_time.dart         # Data models for API response
├── services/
│   ├── prayer_time_service.dart # API service layer
│   └── preferences_service.dart # Local storage service
└── screens/
    ├── prayer_times_screen.dart # Main prayer times display
    └── settings_screen.dart     # Settings page for zone selection
```

## API Response Format

```json
{
  "prayerTime": [
    {
      "hijri": "1447-02-14",
      "date": "08-Aug-2025",
      "day": "Friday",
      "imsak": "05:51:00",
      "fajr": "06:01:00",
      "syuruk": "07:11:00",
      "dhuha": "07:36:00",
      "dhuhr": "13:22:00",
      "asr": "16:41:00",
      "maghrib": "19:28:00",
      "isha": "20:40:00"
    }
  ],
  "status": "OK!",
  "serverTime": "2025-08-08 22:33:16",
  "periodType": "today",
  "lang": "ms_my",
  "zone": "WLY01",
  "bearing": "292° 31′ 16″"
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- JAKIM (Jabatan Kemajuan Islam Malaysia) for providing the e-Solat API
- Flutter team for the amazing framework
- Material Design team for the beautiful design system
