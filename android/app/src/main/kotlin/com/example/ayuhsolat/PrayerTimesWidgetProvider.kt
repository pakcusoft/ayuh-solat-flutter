package com.webgeaz.app.ayuhsolat

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.widget.RemoteViews
import android.app.AlarmManager
import android.os.SystemClock
import java.util.Calendar
import es.antonborri.home_widget.HomeWidgetPlugin

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        // Schedule automatic updates
        scheduleAutoUpdate(context)
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
                val syuruk = widgetData.getString("syuruk", "06:50")
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
                views.setTextViewText(R.id.syuruk_time, syuruk)
                views.setTextViewText(R.id.dhuhr_time, dhuhr)
                views.setTextViewText(R.id.asr_time, asr)
                views.setTextViewText(R.id.maghrib_time, maghrib)
                views.setTextViewText(R.id.isha_time, isha)
                views.setTextViewText(R.id.widget_zone, zone)

                // Update label with selected language
                views.setTextViewText(R.id.label_subuh, widgetData.getString("fajr_label", "Fajr"))
                views.setTextViewText(R.id.label_syuruk, widgetData.getString("syuruk_label", "Syuruk"))
                views.setTextViewText(R.id.label_zohor, widgetData.getString("dhuhr_label", "Dhuhr"))
                views.setTextViewText(R.id.label_asar, widgetData.getString("asr_label", "Asr"))
                views.setTextViewText(R.id.label_maghrib, widgetData.getString("maghrib_label", "Maghrib"))
                views.setTextViewText(R.id.label_isyak, widgetData.getString("isha_label", "Isha"))
                
                // Format the date
                if (!day.isNullOrEmpty() && !date.isNullOrEmpty()) {
                    val shortDay = getShortDay(day)
                    // Extract short date format (e.g., "10 Aug" from "10-Aug-2024")
                    val shortDate = formatShortDate(date)
                    val formattedDate = "$shortDay, $shortDate | "
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
        val defaultColor = android.graphics.Color.parseColor("#BE000000")
        val defaultBg = android.graphics.Color.parseColor("#FFFFFF")
        val highlightColor = android.graphics.Color.parseColor("#FFFFFF")
        val highlightBg = android.graphics.Color.parseColor("#BE000000")

        _highlight(views, R.id.label_subuh, defaultColor, defaultBg)
        _highlight(views, R.id.label_zohor, defaultColor, defaultBg)
        _highlight(views, R.id.label_asar, defaultColor, defaultBg)
        _highlight(views, R.id.label_maghrib, defaultColor, defaultBg)
        _highlight(views, R.id.label_isyak, defaultColor, defaultBg)

        // Highlight the current prayer
        when (currentPrayer) {
            "Fajr" -> _highlight(views, R.id.label_subuh, highlightColor, highlightBg)
            "Dhuhr" -> _highlight(views, R.id.label_zohor, highlightColor, highlightBg)
            "Asr" -> _highlight(views, R.id.label_asar, highlightColor, highlightBg)
            "Maghrib" -> _highlight(views, R.id.label_maghrib, highlightColor, highlightBg)
            "Isha" -> _highlight(views, R.id.label_isyak, highlightColor, highlightBg)
        }
    }

    private fun _highlight(views: RemoteViews, id: Int, textColor: Int, bgColor: Int) {
        views.setInt(id, "setBackgroundColor", bgColor)
        views.setTextColor(id, textColor)
    }
    
    private fun scheduleAutoUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, PrayerTimesWidgetProvider::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Schedule updates every 5 minutes for more responsive current prayer detection
        val intervalMillis = 5 * 60 * 1000L // 5 minutes
        alarmManager.setRepeating(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + intervalMillis,
            intervalMillis,
            pendingIntent
        )
    }
    
    private fun updateCurrentPrayerHighlight(context: Context, views: RemoteViews) {
        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val fajr = widgetData.getString("fajr", "05:50")
            val dhuhr = widgetData.getString("dhuhr", "13:07")
            val asr = widgetData.getString("asr", "16:28")
            val maghrib = widgetData.getString("maghrib", "19:20")
            val isha = widgetData.getString("isha", "20:35")
            val syuruk = widgetData.getString("syuruk", "07:15") // Get syuruk time if available
            
            // Determine current prayer based on current time
            val currentPrayer = getCurrentPrayer(fajr!!, syuruk ?: "07:15", dhuhr!!, asr!!, maghrib!!, isha!!)
            
            // Save updated current prayer back to widget data
            widgetData.edit().putString("currentPrayer", currentPrayer).apply()
            
            // Highlight current prayer
            highlightCurrentPrayer(views, currentPrayer)
        } catch (e: Exception) {
            // If there's an error, fall back to stored currentPrayer value
            val widgetData = HomeWidgetPlugin.getData(context)
            val currentPrayer = widgetData.getString("currentPrayer", "")
            highlightCurrentPrayer(views, currentPrayer)
        }
    }
    
    private fun getCurrentPrayer(fajr: String, syuruk: String, dhuhr: String, asr: String, maghrib: String, isha: String): String {
        val now = Calendar.getInstance()
        val currentTime = String.format("%02d:%02d", now.get(Calendar.HOUR_OF_DAY), now.get(Calendar.MINUTE))
        
        val prayers = listOf(
            "Fajr" to fajr,
            "Dhuhr" to dhuhr,
            "Asr" to asr,
            "Maghrib" to maghrib,
            "Isha" to isha
        )
        
        var currentPrayer = ""
        
        // Find current active prayer (most recent prayer that has passed)
        for (prayer in prayers) {
            val prayerTime = prayer.second
            val prayerName = prayer.first
            
            // Check if current time is after this prayer time
            if (compareTime(currentTime, prayerTime) >= 0) {
                currentPrayer = prayerName
                
                // Special case for Fajr: if Syuruk has passed, Fajr is no longer current
                if (prayerName == "Fajr" && compareTime(currentTime, syuruk) >= 0) {
                    currentPrayer = ""
                }
            }
        }
        
        return currentPrayer
    }
    
    private fun compareTime(time1: String, time2: String): Int {
        val parts1 = time1.split(":")
        val parts2 = time2.split(":")
        
        val hour1 = parts1[0].toInt()
        val minute1 = parts1[1].toInt()
        val hour2 = parts2[0].toInt()
        val minute2 = parts2[1].toInt()
        
        val totalMinutes1 = hour1 * 60 + minute1
        val totalMinutes2 = hour2 * 60 + minute2
        
        return totalMinutes1.compareTo(totalMinutes2)
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = ComponentName(context, PrayerTimesWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }
}
