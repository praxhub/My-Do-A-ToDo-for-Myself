package com.example.mytodo

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class DayPlanWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val backgroundAction = "es.antonborri.home_widget.action.BACKGROUND"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val isDark = readBool(widgetData, "widget_is_dark", false)
            val showCount = readBool(widgetData, "widget_show_count", true)

            val views = RemoteViews(
                context.packageName,
                if (isDark) R.layout.day_plan_widget_dark else R.layout.day_plan_widget_light,
            )

            views.setTextViewText(
                R.id.task_count_text,
                "${readInt(widgetData, "dayplan_task_count", 0)} day plan item(s)",
            )
            views.setViewVisibility(R.id.task_count_text, if (showCount) View.VISIBLE else View.GONE)
            views.setTextViewText(
                R.id.empty_state_text,
                context.getString(R.string.widget_empty_dayplan_text),
            )
            views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_dayplan_title))
            views.setEmptyView(R.id.tasks_list, R.id.empty_state_text)

            val iconTint = color(
                context,
                if (isDark) R.color.widget_icon_dark_fixed else R.color.widget_icon_light_fixed,
            )
            views.setInt(R.id.add_task_button, "setColorFilter", iconTint)
            views.setInt(R.id.open_app_icon, "setColorFilter", iconTint)

            val openAppUri = Uri.parse("mydo://widget?action=open&target=dayplan")
            val openAppPendingIntent = createLaunchPendingIntent(
                context = context,
                uri = openAppUri,
                requestCode = requestCode("open", "app", widgetId),
            )
            views.setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_title, openAppPendingIntent)

            val quickAddPendingIntent = createQuickAddPendingIntent(context, widgetId, "dayPlan")
            views.setOnClickPendingIntent(R.id.add_task_button, quickAddPendingIntent)

            val listIntent = Intent(context, WidgetTaskListService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                putExtra("kind", "dayPlan")
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.tasks_list, listIntent)
            views.setPendingIntentTemplate(
                R.id.tasks_list,
                createToggleTemplatePendingIntent(context, widgetId),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.tasks_list)
        }
    }

    private fun createQuickAddPendingIntent(
        context: Context,
        widgetId: Int,
        kind: String,
    ): PendingIntent {
        val intent = Intent(context, WidgetQuickAddActivity::class.java).apply {
            putExtra("kind", kind)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getActivity(
            context,
            requestCode("quick_add", kind, widgetId),
            intent,
            flags,
        )
    }

    private fun createToggleTemplatePendingIntent(
        context: Context,
        widgetId: Int,
    ): PendingIntent {
        val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            action = backgroundAction
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode("toggle_template", "dayPlan", widgetId),
            intent,
            flags,
        )
    }

    private fun createLaunchPendingIntent(
        context: Context,
        uri: Uri,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            data = uri
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        if (Build.VERSION.SDK_INT < 34) {
            return PendingIntent.getActivity(context, requestCode, intent, flags)
        }
        val options = ActivityOptions.makeBasic()
        if (Build.VERSION.SDK_INT >= 35) {
            options.setPendingIntentCreatorBackgroundActivityStartMode(
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
            )
        } else {
            options.pendingIntentBackgroundActivityStartMode =
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            flags,
            options.toBundle(),
        )
    }

    private fun requestCode(action: String, token: String, widgetId: Int): Int {
        return "$action|$token|$widgetId|dayPlan".hashCode()
    }

    private fun readInt(prefs: SharedPreferences, key: String, fallback: Int): Int {
        val raw = prefs.all[key] ?: return fallback
        return when (raw) {
            is Int -> raw
            is Long -> raw.toInt()
            is Double -> raw.toInt()
            is Float -> raw.toInt()
            is String -> raw.toIntOrNull() ?: fallback
            else -> fallback
        }
    }

    private fun readBool(prefs: SharedPreferences, key: String, fallback: Boolean): Boolean {
        val raw = prefs.all[key] ?: return fallback
        return when (raw) {
            is Boolean -> raw
            is String -> raw.equals("true", true) || raw == "1"
            is Int -> raw != 0
            is Long -> raw != 0L
            else -> fallback
        }
    }

    private fun color(context: Context, colorRes: Int): Int {
        return ContextCompat.getColor(context, colorRes)
    }
}
