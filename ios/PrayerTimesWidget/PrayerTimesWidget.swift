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

        let prayerTimes = PrayerTimeEntry(
            fajr: fajr,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            nextPrayer: nextPrayer,
            nextPrayerTime: nextPrayerTime
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

    static let placeholder = PrayerTimeEntry(fajr: "06:00", dhuhr: "13:00", asr: "16:00", maghrib: "19:00", isha: "20:00", nextPrayer: "Fajr", nextPrayerTime: "06:00")
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let prayerTimes: PrayerTimeEntry
}

struct PrayerTimesWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Next Prayer: \(entry.prayerTimes.nextPrayer) at \(entry.prayerTimes.nextPrayerTime)")
            HStack {
                VStack {
                    Text("Fajr").font(.custom("UbuntuCondensed-Regular", size: 12))
                    Text(entry.prayerTimes.fajr).font(.custom("UbuntuCondensed-Regular", size: 14))
                }
                VStack {
                    Text("Dhuhr").font(.custom("UbuntuCondensed-Regular", size: 12))
                    Text(entry.prayerTimes.dhuhr).font(.custom("UbuntuCondensed-Regular", size: 14))
                }
                VStack {
                    Text("Asr").font(.custom("UbuntuCondensed-Regular", size: 12))
                    Text(entry.prayerTimes.asr).font(.custom("UbuntuCondensed-Regular", size: 14))
                }
                VStack {
                    Text("Maghrib").font(.custom("UbuntuCondensed-Regular", size: 12))
                    Text(entry.prayerTimes.maghrib).font(.custom("UbuntuCondensed-Regular", size: 14))
                }
                VStack {
                    Text("Isha").font(.custom("UbuntuCondensed-Regular", size: 12))
                    Text(entry.prayerTimes.isha).font(.custom("UbuntuCondensed-Regular", size: 14))
                }
            }
        }
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
