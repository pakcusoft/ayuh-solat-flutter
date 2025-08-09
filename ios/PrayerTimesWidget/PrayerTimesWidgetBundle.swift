//
//  PrayerTimesWidgetBundle.swift
//  PrayerTimesWidget
//
//  Created by Khairulfaizie Mat Isa on 09/08/2025.
//

import WidgetKit
import SwiftUI

struct PrayerTimesWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        PrayerTimesWidgetControl()
        PrayerTimesWidgetLiveActivity()
    }
}
