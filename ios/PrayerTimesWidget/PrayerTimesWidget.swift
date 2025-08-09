import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), prayerTimes: PrayerTimeEntry.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), prayerTimes: PrayerTimeEntry.placeholder)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.example.ayuhsolat")
        let fajr = userDefaults?.string(forKey: "fajr") ?? "-"
        let dhuhr = userDefaults?.string(forKey: "dhuhr") ?? "-"
        let asr = userDefaults?.string(forKey: "asr") ?? "-"
        let maghrib = userDefaults?.string(forKey: "maghrib") ?? "-"
        let isha = userDefaults?.string(forKey: "isha") ?? "-"
        let nextPrayer = userDefaults?.string(forKey: "nextPrayer") ?? "-"
        let nextPrayerTime = userDefaults?.string(forKey: "nextPrayerTime") ?? "-"
        let zone = userDefaults?.string(forKey: "zone") ?? "WLY01"
        let hijri = userDefaults?.string(forKey: "hijri") ?? "15 Muharram 1446H"
        let date = userDefaults?.string(forKey: "date") ?? ""
        let day = userDefaults?.string(forKey: "day") ?? ""

        let prayerTimes = PrayerTimeEntry(
            fajr: fajr,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            nextPrayer: nextPrayer,
            nextPrayerTime: nextPrayerTime,
            zone: zone,
            hijri: hijri,
            date: date,
            day: day
        )

        let entry = SimpleEntry(date: Date(), prayerTimes: prayerTimes)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct PrayerTimeEntry {
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let nextPrayer: String
    let nextPrayerTime: String
    let zone: String
    let hijri: String
    let date: String
    let day: String

    static let placeholder = PrayerTimeEntry(
        fajr: "05:50", 
        dhuhr: "13:07", 
        asr: "16:28", 
        maghrib: "19:20", 
        isha: "20:35", 
        nextPrayer: "Dhuhr", 
        nextPrayerTime: "13:07",
        zone: "WLY01",
        hijri: "15 Muharram 1446H",
        date: "17 Jul 2024",
        day: "Wednesday"
    )
    
    var formattedDate: String {
        if !day.isEmpty && !date.isEmpty {
            return "\(day), \(date)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, dd MMM yyyy"
            return formatter.string(from: Date())
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let prayerTimes: PrayerTimeEntry
}

struct PrayerTimesWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            // Header Section
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prayer Times")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#2E7D32"))
                    Text(entry.prayerTimes.hijri)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.prayerTimes.zone)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#2E7D32"))
                    Text(entry.prayerTimes.formattedDate)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            // Next Prayer Section
            HStack {
                Text("Next: ")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#2E7D32"))
                Text(entry.prayerTimes.nextPrayer)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#2E7D32"))
                Text(" at ")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#2E7D32"))
                Text(entry.prayerTimes.nextPrayerTime)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#2E7D32"))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(hex: "#E8F5E8"))
            .cornerRadius(6)
            
            // Prayer Times Grid
            VStack(spacing: 6) {
                // Row 1: Fajr and Dhuhr
                HStack {
                    prayerTimeRow(name: "Fajr", time: entry.prayerTimes.fajr)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 20)
                    prayerTimeRow(name: "Dhuhr", time: entry.prayerTimes.dhuhr)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                // Row 2: Asr and Maghrib
                HStack {
                    prayerTimeRow(name: "Asr", time: entry.prayerTimes.asr)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 20)
                    prayerTimeRow(name: "Maghrib", time: entry.prayerTimes.maghrib)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                // Row 3: Isha (Centered)
                HStack {
                    Spacer()
                    prayerTimeRow(name: "Isha", time: entry.prayerTimes.isha)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .widgetURL(URL(string: "ayuhsolat://open"))
    }
    
    private func prayerTimeRow(name: String, time: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            Spacer()
            Text(time)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@main
struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) {
            entry in
            PrayerTimesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Displays the daily prayer times.")
        .supportedFamilies([.systemMedium])
    }
}

struct PrayerTimesWidget_Previews: PreviewProvider {
    static var previews: some View {
        PrayerTimesWidgetEntryView(entry: SimpleEntry(date: Date(), prayerTimes: PrayerTimeEntry.placeholder))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
