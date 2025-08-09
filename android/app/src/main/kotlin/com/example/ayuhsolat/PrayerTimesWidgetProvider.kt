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
            views.setTextViewText(R.id.widget_date, "Sat, 10 Aug")
            views.setTextViewText(R.id.widget_zone, "WLY01")
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
                val zone = widgetData.getString("zone", "WLY01")
                val date = widgetData.getString("date", "")
                val day = widgetData.getString("day", "")
                val currentPrayer = widgetData.getString("currentPrayer", "")
                
                // Update with real data if available
                views.setTextViewText(R.id.fajr_time, fajr)
                views.setTextViewText(R.id.dhuhr_time, dhuhr)
                views.setTextViewText(R.id.asr_time, asr)
                views.setTextViewText(R.id.maghrib_time, maghrib)
                views.setTextViewText(R.id.isha_time, isha)
                views.setTextViewText(R.id.widget_zone, zone)
                
                // Format the date
                if (!day.isNullOrEmpty() && !date.isNullOrEmpty()) {
                    val shortDay = getShortDay(day)
                    // Extract short date format (e.g., "10 Aug" from "10-Aug-2024")
                    val shortDate = formatShortDate(date)
                    val formattedDate = "$shortDay, $shortDate"
                    views.setTextViewText(R.id.widget_date, formattedDate)
                }
                
                // Highlight current prayer
                highlightCurrentPrayer(views, currentPrayer)
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
    
    private fun getShortDay(day: String): String {
        return when (day) {
            "Monday" -> "Mon"
            "Tuesday" -> "Tue"
            "Wednesday" -> "Wed"
            "Thursday" -> "Thu"
            "Friday" -> "Fri"
            "Saturday" -> "Sat"
            "Sunday" -> "Sun"
            else -> day
        }
    }
    
    private fun formatShortDate(date: String): String {
        // Convert "10-Aug-2024" to "10 Aug"
        return try {
            val parts = date.split("-")
            if (parts.size >= 2) {
                "${parts[0]} ${parts[1]}"
            } else {
                date
            }
        } catch (e: Exception) {
            date
        }
    }
    
    private fun highlightCurrentPrayer(views: RemoteViews, currentPrayer: String?) {
        // Reset all prayer times to default color first
        val defaultColor = android.graphics.Color.parseColor("#333333")
        val highlightColor = android.graphics.Color.parseColor("#FF5722") // Orange color for current prayer
        
        views.setTextColor(R.id.fajr_time, defaultColor)
        views.setTextColor(R.id.dhuhr_time, defaultColor)
        views.setTextColor(R.id.asr_time, defaultColor)
        views.setTextColor(R.id.maghrib_time, defaultColor)
        views.setTextColor(R.id.isha_time, defaultColor)
        
        // Highlight the current prayer
        when (currentPrayer) {
            "Fajr" -> views.setTextColor(R.id.fajr_time, highlightColor)
            "Dhuhr" -> views.setTextColor(R.id.dhuhr_time, highlightColor)
            "Asr" -> views.setTextColor(R.id.asr_time, highlightColor)
            "Maghrib" -> views.setTextColor(R.id.maghrib_time, highlightColor)
            "Isha" -> views.setTextColor(R.id.isha_time, highlightColor)
        }
    }
}
