package com.example.ayuhsolat

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
            
            // Set default values
            views.setTextViewText(R.id.fajr_time, "05:50")
            views.setTextViewText(R.id.dhuhr_time, "13:07")
            views.setTextViewText(R.id.asr_time, "16:28")
            views.setTextViewText(R.id.maghrib_time, "19:20")
            views.setTextViewText(R.id.isha_time, "20:35")

            // Try to get real prayer time data
            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                val fajr = widgetData.getString("fajr", "05:50")
                val dhuhr = widgetData.getString("dhuhr", "13:07")
                val asr = widgetData.getString("asr", "16:28")
                val maghrib = widgetData.getString("maghrib", "19:20")
                val isha = widgetData.getString("isha", "20:35")
                
                // Update with real data if available
                views.setTextViewText(R.id.fajr_time, fajr)
                views.setTextViewText(R.id.dhuhr_time, dhuhr)
                views.setTextViewText(R.id.asr_time, asr)
                views.setTextViewText(R.id.maghrib_time, maghrib)
                views.setTextViewText(R.id.isha_time, isha)
            } catch (e: Exception) {
                // Keep default values if data fetching fails
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
