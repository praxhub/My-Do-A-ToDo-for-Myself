package com.example.mytodo

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Paint
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class WidgetTaskListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        val kind = intent.getStringExtra("kind") ?: "todo"
        return TaskListFactory(this, widgetId, kind)
    }
}

private class TaskListFactory(
    private val service: RemoteViewsService,
    private val widgetId: Int,
    private val kind: String,
) : RemoteViewsService.RemoteViewsFactory {

    private data class WidgetTask(
        val id: String,
        val title: String,
        val isCompleted: Boolean,
    )

    private val tasks = mutableListOf<WidgetTask>()
    private var isDark = false

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val prefs = HomeWidgetPlugin.getData(service)
        isDark = readBool(prefs, "widget_is_dark", false)
        val maxItems = readInt(prefs, "widget_max_items", 20).coerceIn(1, 100)
        val key = if (kind == "dayPlan") "dayplan_tasks_json" else "todo_tasks_json"
        val raw = readString(prefs, key, "[]")

        tasks.clear()
        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue
                val id = item.optString("id")
                if (id.isBlank()) continue
                val isCompleted = item.optBoolean("isCompleted", false)
                tasks.add(
                    WidgetTask(
                        id = id,
                        title = item.optString("title", "Untitled Task"),
                        isCompleted = isCompleted,
                    ),
                )
                if (tasks.size >= maxItems) break
            }
        } catch (_: Exception) {
            tasks.clear()
        }
    }

    override fun onDestroy() {
        tasks.clear()
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position !in tasks.indices) {
            return RemoteViews(service.packageName, android.R.layout.simple_list_item_1)
        }
        val task = tasks[position]
        val views = RemoteViews(
            service.packageName,
            if (isDark) R.layout.widget_task_item_dark else R.layout.widget_task_item_light,
        )
        views.setTextViewText(R.id.task_title, task.title)
        views.setImageViewResource(
            R.id.task_checkbox,
            if (task.isCompleted) android.R.drawable.checkbox_on_background
            else android.R.drawable.checkbox_off_background,
        )
        views.setTextColor(
            R.id.task_title,
            color(
                if (task.isCompleted) {
                    if (isDark) R.color.widget_task_done_dark_fixed
                    else R.color.widget_task_done_light_fixed
                } else {
                    if (isDark) R.color.widget_task_title_dark_fixed
                    else R.color.widget_task_title_light_fixed
                },
            ),
        )
        views.setInt(
            R.id.task_title,
            "setPaintFlags",
            if (task.isCompleted) Paint.STRIKE_THRU_TEXT_FLAG else 0,
        )
        views.setInt(
            R.id.task_checkbox,
            "setColorFilter",
            color(
                if (isDark) R.color.widget_icon_dark_fixed else R.color.widget_icon_light_fixed,
            ),
        )

        val fillInIntent = Intent().apply {
            data = android.net.Uri.parse(
                "mydo://widget?action=toggle&kind=$kind&taskId=${android.net.Uri.encode(task.id)}",
            )
        }
        views.setOnClickFillInIntent(R.id.task_checkbox, fillInIntent)
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long {
        if (position !in tasks.indices) return position.toLong()
        return tasks[position].id.hashCode().toLong()
    }

    override fun hasStableIds(): Boolean = true

    private fun readString(
        prefs: android.content.SharedPreferences,
        key: String,
        fallback: String,
    ): String {
        val raw = prefs.all[key] ?: return fallback
        return raw.toString()
    }

    private fun readInt(
        prefs: android.content.SharedPreferences,
        key: String,
        fallback: Int,
    ): Int {
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

    private fun readBool(
        prefs: android.content.SharedPreferences,
        key: String,
        fallback: Boolean,
    ): Boolean {
        val raw = prefs.all[key] ?: return fallback
        return when (raw) {
            is Boolean -> raw
            is String -> raw.equals("true", true) || raw == "1"
            is Int -> raw != 0
            is Long -> raw != 0L
            else -> fallback
        }
    }

    private fun color(colorRes: Int): Int {
        return ContextCompat.getColor(service, colorRes)
    }
}
