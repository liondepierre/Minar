package com.minar.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

object MinarWidgetHelper {
    private const val PREFS_NAME = "minar_widget_storage"
    private const val KEY_WIDGET_DATA = "widget_json_payload"

    fun saveAndBroadcastData(context: Context, data: Map<String, Any?>) {
        val json = JSONObject(data)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_WIDGET_DATA, json.toString()).apply()

        updateAllWidgets(context)
    }

    fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)

        // 1. Update Next Prayer Widgets
        val nextPrayerIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, MinarNextPrayerWidget::class.java)
        )
        for (id in nextPrayerIds) {
            updateNextPrayerWidget(context, appWidgetManager, id)
        }

        // 2. Update Timetable Widgets
        val timetableIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, MinarTimetableWidget::class.java)
        )
        for (id in timetableIds) {
            updateTimetableWidget(context, appWidgetManager, id)
        }

        // 3. Update Vertical Schedule Widgets
        val verticalIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, MinarVerticalWidget::class.java)
        )
        for (id in verticalIds) {
            updateVerticalWidget(context, appWidgetManager, id)
        }

        // 4. Update Minimal Bar Widgets
        val barIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, MinarBarWidget::class.java)
        )
        for (id in barIds) {
            updateBarWidget(context, appWidgetManager, id)
        }
    }

    private fun getLaunchPendingIntent(context: Context): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent(context, MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )
    }

    fun updateNextPrayerWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val rawJson = prefs.getString(KEY_WIDGET_DATA, null)

        val views = RemoteViews(context.packageName, R.layout.widget_next_prayer)
        views.setOnClickPendingIntent(R.id.widget_next_prayer_root, getLaunchPendingIntent(context))

        if (rawJson != null) {
            try {
                val json = JSONObject(rawJson)
                val city = json.optString("city", "Ikast")
                val country = json.optString("country", "Denmark")
                val hijri = json.optString("hijriDate", "")
                val nextName = json.optString("nextName", "İMSAK")
                val nextTime = json.optString("nextTime", "06:05")
                val nextRemaining = json.optString("nextRemaining", "")
                val isTomorrow = json.optBoolean("isTomorrowFajr", false)

                views.setTextViewText(R.id.widget_next_city, "$city, $country")
                views.setTextViewText(R.id.widget_next_hijri, hijri)
                views.setTextViewText(R.id.widget_next_name, nextName.uppercase())
                views.setTextViewText(R.id.widget_next_time, nextTime)

                val badgeText = if (isTomorrow) "TOMORROW" else "NEXT"
                views.setTextViewText(R.id.widget_next_badge, badgeText)

                if (nextRemaining.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_next_remaining, "in $nextRemaining")
                    views.setViewVisibility(R.id.widget_next_remaining_container, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_next_remaining_container, View.GONE)
                }
            } catch (_: Exception) {}
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    fun updateTimetableWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val rawJson = prefs.getString(KEY_WIDGET_DATA, null)

        val views = RemoteViews(context.packageName, R.layout.widget_timetable)
        views.setOnClickPendingIntent(R.id.widget_timetable_root, getLaunchPendingIntent(context))

        if (rawJson != null) {
            try {
                val json = JSONObject(rawJson)
                val city = json.optString("city", "Ikast")
                val country = json.optString("country", "Denmark")
                val hijri = json.optString("hijriDate", "")
                val gregorian = json.optString("gregorianDate", "")
                val isTomorrow = json.optBoolean("isTomorrowFajr", false)
                val prayers = json.optJSONArray("prayers") ?: JSONArray()

                val prefix = if (isTomorrow) "Tomorrow • " else "Minar • "
                views.setTextViewText(R.id.widget_tt_title, "$prefix$city")

                val dateStr = if (hijri.isNotEmpty()) "$gregorian • $hijri" else gregorian
                views.setTextViewText(R.id.widget_tt_date, dateStr)

                val cellIds = intArrayOf(
                    R.id.widget_cell_0, R.id.widget_cell_1, R.id.widget_cell_2,
                    R.id.widget_cell_3, R.id.widget_cell_4, R.id.widget_cell_5
                )
                val nameIds = intArrayOf(
                    R.id.widget_name_0, R.id.widget_name_1, R.id.widget_name_2,
                    R.id.widget_name_3, R.id.widget_name_4, R.id.widget_name_5
                )
                val timeIds = intArrayOf(
                    R.id.widget_time_0, R.id.widget_time_1, R.id.widget_time_2,
                    R.id.widget_time_3, R.id.widget_time_4, R.id.widget_time_5
                )

                for (i in 0 until minOf(prayers.length(), 6)) {
                    val p = prayers.getJSONObject(i)
                    val pName = p.optString("name", "")
                    val pTime = p.optString("time", "")
                    val isNext = p.optBoolean("isNext", false)

                    views.setTextViewText(nameIds[i], pName.uppercase())
                    views.setTextViewText(timeIds[i], pTime)

                    if (isNext) {
                        views.setInt(cellIds[i], "setBackgroundResource", R.drawable.widget_cell_active)
                        views.setTextColor(nameIds[i], 0xFFE8C582.toInt())
                        views.setTextColor(timeIds[i], 0xFFF4DC9F.toInt())
                    } else {
                        views.setInt(cellIds[i], "setBackgroundResource", R.drawable.widget_cell_normal)
                        views.setTextColor(nameIds[i], 0xFF7E8EA6.toInt())
                        views.setTextColor(timeIds[i], 0xFFF3F5F8.toInt())
                    }
                }
            } catch (_: Exception) {}
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    fun updateVerticalWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val rawJson = prefs.getString(KEY_WIDGET_DATA, null)

        val views = RemoteViews(context.packageName, R.layout.widget_vertical)
        views.setOnClickPendingIntent(R.id.widget_vertical_root, getLaunchPendingIntent(context))

        if (rawJson != null) {
            try {
                val json = JSONObject(rawJson)
                val city = json.optString("city", "Ikast")
                val country = json.optString("country", "Denmark")
                val hijri = json.optString("hijriDate", "")
                val gregorian = json.optString("gregorianDate", "")
                val isTomorrow = json.optBoolean("isTomorrowFajr", false)
                val prayers = json.optJSONArray("prayers") ?: JSONArray()

                val prefix = if (isTomorrow) "Tomorrow • " else ""
                views.setTextViewText(R.id.widget_v_title, "$prefix$city, $country")

                val dateStr = if (hijri.isNotEmpty()) "$gregorian • $hijri" else gregorian
                views.setTextViewText(R.id.widget_v_date, dateStr)

                val dotIds = intArrayOf(
                    R.id.widget_v_dot_0, R.id.widget_v_dot_1, R.id.widget_v_dot_2,
                    R.id.widget_v_dot_3, R.id.widget_v_dot_4, R.id.widget_v_dot_5
                )
                val nameIds = intArrayOf(
                    R.id.widget_v_name_0, R.id.widget_v_name_1, R.id.widget_v_name_2,
                    R.id.widget_v_name_3, R.id.widget_v_name_4, R.id.widget_v_name_5
                )
                val subIds = intArrayOf(
                    R.id.widget_v_sub_0, R.id.widget_v_sub_1, R.id.widget_v_sub_2,
                    R.id.widget_v_sub_3, R.id.widget_v_sub_4, R.id.widget_v_sub_5
                )
                val timeIds = intArrayOf(
                    R.id.widget_v_time_0, R.id.widget_v_time_1, R.id.widget_v_time_2,
                    R.id.widget_v_time_3, R.id.widget_v_time_4, R.id.widget_v_time_5
                )

                val englishSubs = arrayOf("Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha")

                for (i in 0 until minOf(prayers.length(), 6)) {
                    val p = prayers.getJSONObject(i)
                    val pName = p.optString("name", "")
                    val pTime = p.optString("time", "")
                    val isNext = p.optBoolean("isNext", false)

                    views.setTextViewText(nameIds[i], pName)
                    views.setTextViewText(subIds[i], englishSubs[i])
                    views.setTextViewText(timeIds[i], pTime)

                    if (isNext) {
                        views.setImageViewResource(dotIds[i], R.drawable.widget_dot_gold)
                        views.setTextColor(nameIds[i], 0xFFE8C582.toInt())
                        views.setTextColor(timeIds[i], 0xFFF4DC9F.toInt())
                    } else {
                        views.setImageViewResource(dotIds[i], R.drawable.widget_dot_dim)
                        views.setTextColor(nameIds[i], 0xFFF3F5F8.toInt())
                        views.setTextColor(timeIds[i], 0xFFF3F5F8.toInt())
                    }
                }
            } catch (_: Exception) {}
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    fun updateBarWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val rawJson = prefs.getString(KEY_WIDGET_DATA, null)

        val views = RemoteViews(context.packageName, R.layout.widget_bar)
        views.setOnClickPendingIntent(R.id.widget_bar_root, getLaunchPendingIntent(context))

        if (rawJson != null) {
            try {
                val json = JSONObject(rawJson)
                val prayers = json.optJSONArray("prayers") ?: JSONArray()

                val cellIds = intArrayOf(
                    R.id.widget_bar_cell_0, R.id.widget_bar_cell_1, R.id.widget_bar_cell_2,
                    R.id.widget_bar_cell_3, R.id.widget_bar_cell_4, R.id.widget_bar_cell_5
                )
                val nameIds = intArrayOf(
                    R.id.widget_bar_name_0, R.id.widget_bar_name_1, R.id.widget_bar_name_2,
                    R.id.widget_bar_name_3, R.id.widget_bar_name_4, R.id.widget_bar_name_5
                )
                val timeIds = intArrayOf(
                    R.id.widget_bar_time_0, R.id.widget_bar_time_1, R.id.widget_bar_time_2,
                    R.id.widget_bar_time_3, R.id.widget_bar_time_4, R.id.widget_bar_time_5
                )

                for (i in 0 until minOf(prayers.length(), 6)) {
                    val p = prayers.getJSONObject(i)
                    val pName = p.optString("name", "")
                    val pTime = p.optString("time", "")
                    val isNext = p.optBoolean("isNext", false)

                    // Short 3-char name
                    val shortName = if (pName.length > 3) pName.substring(0, 3).uppercase() else pName.uppercase()
                    views.setTextViewText(nameIds[i], shortName)
                    views.setTextViewText(timeIds[i], pTime)

                    if (isNext) {
                        views.setInt(cellIds[i], "setBackgroundResource", R.drawable.widget_cell_active)
                        views.setTextColor(nameIds[i], 0xFFE8C582.toInt())
                        views.setTextColor(timeIds[i], 0xFFF4DC9F.toInt())
                    } else {
                        views.setInt(cellIds[i], "setBackgroundResource", R.drawable.widget_cell_normal)
                        views.setTextColor(nameIds[i], 0xFF7E8EA6.toInt())
                        views.setTextColor(timeIds[i], 0xFFF3F5F8.toInt())
                    }
                }
            } catch (_: Exception) {}
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
