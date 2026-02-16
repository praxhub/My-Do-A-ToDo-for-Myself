package com.example.mytodo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TodayTaskWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.today_task_widget)

            val count = widgetData.getInt("today_task_count", 0)
            val tasks = widgetData.getString("today_task_titles", "No tasks due today") ?: "No tasks due today"

            views.setTextViewText(R.id.task_count_text, "$count task(s) due today")
            views.setTextViewText(R.id.task_list_text, tasks)

            val launchIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
            views.setOnClickPendingIntent(R.id.quick_add_button, launchIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
