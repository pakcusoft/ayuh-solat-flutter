package com.example.ayuhsolat

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            // Always use 4x1 layout for consistent mobile experience
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget_4x1)
            
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

            // Add click functionality to open the app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
