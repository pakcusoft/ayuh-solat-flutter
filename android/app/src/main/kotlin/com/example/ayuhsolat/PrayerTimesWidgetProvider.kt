package com.example.ayuhsolat

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getWidgetData(context)
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget).apply {
                val fajr = widgetData.getString("fajr", "-")
                val dhuhr = widgetData.getString("dhuhr", "-")
                val asr = widgetData.getString("asr", "-")
                val maghrib = widgetData.getString("maghrib", "-")
                val isha = widgetData.getString("isha", "-")

                setTextViewText(R.id.fajr_time, fajr)
                setTextViewText(R.id.dhuhr_time, dhuhr)
                setTextViewText(R.id.asr_time, asr)
                setTextViewText(R.id.maghrib_time, maghrib)
                setTextViewText(R.id.isha_time, isha)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
