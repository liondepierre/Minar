package com.minar.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

object MinarWidgetHelper {
    private const val PREFS_NAME = "minar_widget_storage"
    private const val KEY_WIDGET_DATA = "widget_json_payload"

    data class AccentStyle(
        val activeCellRes: Int,
        val activeRowRes: Int,
        val pillRes: Int,
        val dotRes: Int,
        val accentColor: Int,
        val accentLightColor: Int
    )

    data class WidgetStyle(
        val bgRes: Int,
        val normalCellRes: Int,
        val accent: AccentStyle,
        val labelColor: Int,
        val normalTextColor: Int,
        val showHeader: Boolean
    )

    private fun resolveStyle(json: JSONObject): WidgetStyle {
        val theme = json.optString("widgetTheme", "midnight")
        val accentName = json.optString("widgetAccent", "gold")
        val showHeader = json.optBoolean("widgetShowHeader", true)

        val bgRes = when (theme) {
            "amoled" -> R.drawable.widget_bg_amoled
            "glass" -> R.drawable.widget_bg_glass
            "transparent" -> R.drawable.widget_bg_transparent
            else -> R.drawable.widget_bg_midnight
        }

        val normalCellRes = when (theme) {
            "amoled" -> R.drawable.widget_cell_normal_amoled
            "glass" -> R.drawable.widget_cell_normal_glass
            else -> R.drawable.widget_cell_normal
        }

        val accent = when (accentName) {
            "emerald" -> AccentStyle(
                R.drawable.widget_cell_active_emerald,
                R.drawable.widget_row_active_emerald,
                R.drawable.widget_pill_emerald,
                R.drawable.widget_dot_emerald,
                0xFF4ADE80.toInt(),
                0xFF86EFAC.toInt()
            )
            "white" -> AccentStyle(
                R.drawable.widget_cell_active_white,
                R.drawable.widget_row_active_white,
                R.drawable.widget_pill_white,
                R.drawable.widget_dot_white,
                0xFFFFFFFF.toInt(),
                0xFFF3F4F6.toInt()
            )
            "blue" -> AccentStyle(
                R.drawable.widget_cell_active_blue,
                R.drawable.widget_row_active_blue,
                R.drawable.widget_pill_blue,
                R.drawable.widget_dot_blue,
                0xFF60A5FA.toInt(),
                0xFF93C5FD.toInt()
            )
            else -> AccentStyle(
                R.drawable.widget_cell_active_gold,
                R.drawable.widget_row_active_gold,
                R.drawable.widget_pill_gold,
                R.drawable.widget_dot_gold,
                0xFFE8C582.toInt(),
                0xFFF4DC9F.toInt()
            )
        }

        return WidgetStyle(
            bgRes = bgRes,
            normalCellRes = normalCellRes,
            accent = accent,
            labelColor = 0xFF8E9BAE.toInt(),
            normalTextColor = 0xFFFFFFFF.toInt(),
            showHeader = showHeader
        )
    }

    fun saveAndBroadcastData(context: Context, data: Map<String, Any?>) {
        val json = JSONObject(data)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_WIDGET_DATA, json.toString()).apply()

        updateAllWidgets(context)
    }

    fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)

        // 1. Next Prayer Widgets
        val nextPrayerIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, MinarNextPrayerWidget::class.java)
        )
        for (id in nextPrayerIds) {
            updateNextPrayerWidget(context, appWidgetManager, id)
        }

        // 2. Timetable Widgets
        val timetableIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, MinarTimetableWidget::class.java)
        )
        for (id in timetableIds) {
            updateTimetableWidget(context, appWidgetManager, id)
        }

        // 3. Vertical Schedule Widgets
        val verticalIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, MinarVerticalWidget::class.java)
        )
        for (id in verticalIds) {
            updateVerticalWidget(context, appWidgetManager, id)
        }

        // 4. Minimal Bar Widgets
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
                val style = resolveStyle(json)
                val textSizeMode = json.optString("widgetTextSize", "standard")

                views.setInt(R.id.widget_next_prayer_root, "setBackgroundResource", style.bgRes)
                views.setViewVisibility(R.id.widget_next_header, if (style.showHeader) View.VISIBLE else View.GONE)

                val city = json.optString("city", "Ikast")
                val hijri = json.optString("hijriDate", "")
                val nextName = json.optString("nextName", "İMSAK")
                val nextTime = json.optString("nextTime", "06:05")
                val nextRemaining = json.optString("nextRemaining", "")
                val isTomorrow = json.optBoolean("isTomorrowFajr", false)

                // Shorten hijri date for clean header fit
                val shortHijri = if (hijri.isNotEmpty()) {
                    val parts = hijri.split(" ")
                    if (parts.size >= 2) "${parts[0]} ${parts[1]}" else hijri
                } else ""

                views.setTextViewText(R.id.widget_next_city, "Minar • $city")
                views.setTextColor(R.id.widget_next_city, style.accent.accentColor)
                views.setTextViewTextSize(R.id.widget_next_city, TypedValue.COMPLEX_UNIT_SP, 10.5f)

                views.setTextViewText(R.id.widget_next_hijri, shortHijri)
                views.setTextViewTextSize(R.id.widget_next_hijri, TypedValue.COMPLEX_UNIT_SP, 9.5f)

                val (nameSize, timeSize, remSize) = when (textSizeMode) {
                    "xlarge" -> Triple(14f, 27f, 10f)
                    "large" -> Triple(13.5f, 25f, 9.5f)
                    else -> Triple(13f, 23f, 9f)
                }

                views.setTextViewText(R.id.widget_next_name, nextName.uppercase())
                views.setTextColor(R.id.widget_next_name, style.accent.accentColor)
                views.setTextViewTextSize(R.id.widget_next_name, TypedValue.COMPLEX_UNIT_SP, nameSize)

                views.setTextViewText(R.id.widget_next_time, nextTime)
                views.setTextViewTextSize(R.id.widget_next_time, TypedValue.COMPLEX_UNIT_SP, timeSize)
                views.setTextColor(R.id.widget_next_time, 0xFFFFFFFF.toInt())

                val badgeText = if (isTomorrow) "TOMORROW" else "NEXT"
                views.setTextViewText(R.id.widget_next_badge, badgeText)
                views.setInt(R.id.widget_next_badge, "setBackgroundResource", style.accent.pillRes)
                views.setTextColor(R.id.widget_next_badge, style.accent.accentColor)
                views.setTextViewTextSize(R.id.widget_next_badge, TypedValue.COMPLEX_UNIT_SP, 8f)

                if (nextRemaining.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_next_remaining, "in $nextRemaining")
                    views.setInt(R.id.widget_next_remaining_container, "setBackgroundResource", style.accent.pillRes)
                    views.setTextColor(R.id.widget_next_remaining, style.accent.accentLightColor)
                    views.setTextViewTextSize(R.id.widget_next_remaining, TypedValue.COMPLEX_UNIT_SP, remSize)
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
                val style = resolveStyle(json)
                val textSizeMode = json.optString("widgetTextSize", "standard")

                views.setInt(R.id.widget_timetable_root, "setBackgroundResource", style.bgRes)
                views.setViewVisibility(R.id.widget_tt_header, if (style.showHeader) View.VISIBLE else View.GONE)

                val city = json.optString("city", "Ikast")
                val hijri = json.optString("hijriDate", "")
                val gregorian = json.optString("gregorianDate", "")
                val isTomorrow = json.optBoolean("isTomorrowFajr", false)
                val prayers = json.optJSONArray("prayers") ?: JSONArray()

                val prefix = if (isTomorrow) "Tomorrow • " else "Minar • "
                views.setTextViewText(R.id.widget_tt_title, "$prefix$city")
                views.setTextColor(R.id.widget_tt_title, style.accent.accentColor)
                views.setTextViewTextSize(R.id.widget_tt_title, TypedValue.COMPLEX_UNIT_SP, 11.5f)

                val shortDate = if (hijri.isNotEmpty()) {
                    val parts = hijri.split(" ")
                    if (parts.size >= 2) "$gregorian • ${parts[0]} ${parts[1]}" else "$gregorian • $hijri"
                } else gregorian

                views.setTextViewText(R.id.widget_tt_date, shortDate)
                views.setTextViewTextSize(R.id.widget_tt_date, TypedValue.COMPLEX_UNIT_SP, 9.5f)

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

                val (nameSize, timeSize) = when (textSizeMode) {
                    "xlarge" -> Pair(9f, 13.5f)
                    "large" -> Pair(8.5f, 13f)
                    else -> Pair(8f, 12.5f)
                }

                for (i in 0 until minOf(prayers.length(), 6)) {
                    val p = prayers.getJSONObject(i)
                    val pName = p.optString("name", "")
                    val pTime = p.optString("time", "")
                    val isNext = p.optBoolean("isNext", false)

                    views.setTextViewText(nameIds[i], pName.uppercase())
                    views.setTextViewText(timeIds[i], pTime)

                    views.setTextViewTextSize(nameIds[i], TypedValue.COMPLEX_UNIT_SP, nameSize)
                    views.setTextViewTextSize(timeIds[i], TypedValue.COMPLEX_UNIT_SP, timeSize)

                    if (isNext) {
                        views.setInt(cellIds[i], "setBackgroundResource", style.accent.activeCellRes)
                        views.setTextColor(nameIds[i], style.accent.accentColor)
                        views.setTextColor(timeIds[i], style.accent.accentLightColor)
                    } else {
                        views.setInt(cellIds[i], "setBackgroundResource", style.normalCellRes)
                        views.setTextColor(nameIds[i], style.labelColor)
                        views.setTextColor(timeIds[i], style.normalTextColor)
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
                val style = resolveStyle(json)
                val textSizeMode = json.optString("widgetTextSize", "standard")

                views.setInt(R.id.widget_vertical_root, "setBackgroundResource", style.bgRes)
                views.setViewVisibility(R.id.widget_v_header, if (style.showHeader) View.VISIBLE else View.GONE)

                val city = json.optString("city", "Ikast")
                val hijri = json.optString("hijriDate", "")
                val gregorian = json.optString("gregorianDate", "")
                val isTomorrow = json.optBoolean("isTomorrowFajr", false)
                val prayers = json.optJSONArray("prayers") ?: JSONArray()

                val prefix = if (isTomorrow) "Tomorrow • " else "Minar • "
                views.setTextViewText(R.id.widget_v_title, "$prefix$city")
                views.setTextColor(R.id.widget_v_title, style.accent.accentColor)
                views.setTextViewTextSize(R.id.widget_v_title, TypedValue.COMPLEX_UNIT_SP, 11.5f)

                val shortDate = if (hijri.isNotEmpty()) {
                    val parts = hijri.split(" ")
                    if (parts.size >= 2) "$gregorian • ${parts[0]} ${parts[1]}" else "$gregorian • $hijri"
                } else gregorian

                views.setTextViewText(R.id.widget_v_date, shortDate)
                views.setTextViewTextSize(R.id.widget_v_date, TypedValue.COMPLEX_UNIT_SP, 10f)

                val rowIds = intArrayOf(
                    R.id.widget_v_row_0, R.id.widget_v_row_1, R.id.widget_v_row_2,
                    R.id.widget_v_row_3, R.id.widget_v_row_4, R.id.widget_v_row_5
                )
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

                val (vNameSize, vSubSize, vTimeSize) = when (textSizeMode) {
                    "xlarge" -> Triple(12f, 9.5f, 13.5f)
                    "large" -> Triple(11.5f, 9f, 13f)
                    else -> Triple(11f, 8.5f, 12.5f)
                }

                val englishSubs = arrayOf("Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha")
                val arabicSubs = arrayOf("الفجر", "الشروق", "الظهر", "العصر", "المغرب", "العشاء")

                for (i in 0 until minOf(prayers.length(), 6)) {
                    val p = prayers.getJSONObject(i)
                    val pName = p.optString("name", "")
                    val pTime = p.optString("time", "")
                    val isNext = p.optBoolean("isNext", false)

                    val subText = if (pName.equals(englishSubs[i], ignoreCase = true)) arabicSubs[i] else arabicSubs[i]

                    views.setTextViewText(nameIds[i], pName)
                    views.setTextViewText(subIds[i], subText)
                    views.setTextViewText(timeIds[i], pTime)

                    views.setTextViewTextSize(nameIds[i], TypedValue.COMPLEX_UNIT_SP, vNameSize)
                    views.setTextViewTextSize(subIds[i], TypedValue.COMPLEX_UNIT_SP, vSubSize)
                    views.setTextViewTextSize(timeIds[i], TypedValue.COMPLEX_UNIT_SP, vTimeSize)

                    if (isNext) {
                        views.setInt(rowIds[i], "setBackgroundResource", style.accent.activeRowRes)
                        views.setImageViewResource(dotIds[i], style.accent.dotRes)
                        views.setTextColor(nameIds[i], style.accent.accentColor)
                        views.setTextColor(subIds[i], style.accent.accentColor)
                        views.setTextColor(timeIds[i], style.accent.accentLightColor)
                    } else {
                        views.setInt(rowIds[i], "setBackgroundResource", 0)
                        views.setImageViewResource(dotIds[i], R.drawable.widget_dot_dim)
                        views.setTextColor(nameIds[i], style.normalTextColor)
                        views.setTextColor(subIds[i], style.labelColor)
                        views.setTextColor(timeIds[i], style.normalTextColor)
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
                val style = resolveStyle(json)
                val textSizeMode = json.optString("widgetTextSize", "standard")

                views.setInt(R.id.widget_bar_root, "setBackgroundResource", style.bgRes)

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

                val (barNameSize, barTimeSize) = when (textSizeMode) {
                    "xlarge" -> Pair(8.5f, 11f)
                    "large" -> Pair(8f, 10.5f)
                    else -> Pair(7.5f, 10f)
                }

                for (i in 0 until minOf(prayers.length(), 6)) {
                    val p = prayers.getJSONObject(i)
                    val pName = p.optString("name", "")
                    val pTime = p.optString("time", "")
                    val isNext = p.optBoolean("isNext", false)

                    val shortName = if (pName.length > 3) pName.substring(0, 3).uppercase() else pName.uppercase()
                    views.setTextViewText(nameIds[i], shortName)
                    views.setTextViewText(timeIds[i], pTime)

                    views.setTextViewTextSize(nameIds[i], TypedValue.COMPLEX_UNIT_SP, barNameSize)
                    views.setTextViewTextSize(timeIds[i], TypedValue.COMPLEX_UNIT_SP, barTimeSize)

                    if (isNext) {
                        views.setInt(cellIds[i], "setBackgroundResource", style.accent.activeCellRes)
                        views.setTextColor(nameIds[i], style.accent.accentColor)
                        views.setTextColor(timeIds[i], style.accent.accentLightColor)
                    } else {
                        views.setInt(cellIds[i], "setBackgroundResource", style.normalCellRes)
                        views.setTextColor(nameIds[i], style.labelColor)
                        views.setTextColor(timeIds[i], style.normalTextColor)
                    }
                }
            } catch (_: Exception) {}
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
