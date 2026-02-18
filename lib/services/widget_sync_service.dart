import 'dart:async';
import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../data/app_database.dart';
import '../data/task_repository.dart';
import '../models/task_item.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static const _todoWidgetName = 'TodayTaskWidgetProvider';
  static const _dayPlanWidgetName = 'DayPlanWidgetProvider';
  static const _themeKey = 'is_dark_mode';
  static const widgetShowAllUnfinishedKey = 'widget_show_all_unfinished';
  static const widgetMaxItemsKey = 'widget_max_items';
  static const widgetShowCountKey = 'widget_show_count';

  static DateTime _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const _minSyncGap = Duration(milliseconds: 250);

  static Future<void> refreshTodayTasks({bool force = false}) async {
    final now = DateTime.now();
    if (!force && now.difference(_lastSyncAt) < _minSyncGap) {
      return;
    }
    _lastSyncAt = now;

    final today = DateTime(now.year, now.month, now.day);
    final showAllUnfinished = _readBool(
      widgetShowAllUnfinishedKey,
      fallback: true,
    );
    final showCount = _readBool(widgetShowCountKey, fallback: true);
    final maxItems = _readInt(widgetMaxItemsKey, fallback: 20).clamp(1, 100);
    final isDarkMode = _readBool(_themeKey, fallback: false);

    final allTasks = TaskRepository.allSorted();
    final todoBaseTasks = allTasks.where((task) {
      if (task.kind != TaskKind.todo) return false;
      if (showAllUnfinished) return true;
      final due = task.dueDate;
      if (due == null) return false;
      return due.year == today.year &&
          due.month == today.month &&
          due.day == today.day;
    }).toList();
    final dayPlanBaseTasks = allTasks.where((task) {
      if (task.kind != TaskKind.dayPlan) return false;
      if (showAllUnfinished) return true;
      final due = task.dueDate;
      if (due == null) return false;
      return due.year == today.year &&
          due.month == today.month &&
          due.day == today.day;
    }).toList();

    bool keepInWidget(TaskItem task) {
      if (!task.isCompleted) return true;
      final completedAt = task.completedAt;
      if (completedAt == null) return false;
      return completedAt.year == today.year &&
          completedAt.month == today.month &&
          completedAt.day == today.day;
    }

    final todoSourceTasks = todoBaseTasks.where(keepInWidget).toList();
    final dayPlanSourceTasks = dayPlanBaseTasks.where(keepInWidget).toList();

    final todoSnapshot = todoSourceTasks
        .take(maxItems)
        .map(
          (task) => {
            'id': task.id,
            'title': task.title,
            'isCompleted': task.isCompleted,
            'kind': task.kind.name,
            'completedAt': task.completedAt?.toIso8601String(),
          },
        )
        .toList();

    final dayPlanSnapshot = dayPlanSourceTasks
        .take(maxItems)
        .map(
          (task) => {
            'id': task.id,
            'title': task.title,
            'isCompleted': task.isCompleted,
            'kind': task.kind.name,
            'completedAt': task.completedAt?.toIso8601String(),
          },
        )
        .toList();

    final todayKey = _dateKey(today);
    await Future.wait([
      HomeWidget.saveWidgetData<int>('todo_task_count', todoSourceTasks.length),
      HomeWidget.saveWidgetData<String>(
        'todo_tasks_json',
        jsonEncode(todoSnapshot),
      ),
      HomeWidget.saveWidgetData<int>(
        'dayplan_task_count',
        dayPlanSourceTasks.length,
      ),
      HomeWidget.saveWidgetData<String>(
        'dayplan_tasks_json',
        jsonEncode(dayPlanSnapshot),
      ),
      // Backward compatibility key for old widget installs.
      HomeWidget.saveWidgetData<int>(
        'today_task_count',
        todoSourceTasks.length,
      ),
      HomeWidget.saveWidgetData<String>(
        'today_tasks_json',
        jsonEncode(todoSnapshot),
      ),
      HomeWidget.saveWidgetData<String>(
        'snapshot_updated_at',
        now.toIso8601String(),
      ),
      HomeWidget.saveWidgetData<bool>('widget_is_dark', isDarkMode),
      HomeWidget.saveWidgetData<bool>(
        widgetShowAllUnfinishedKey,
        showAllUnfinished,
      ),
      HomeWidget.saveWidgetData<int>(widgetMaxItemsKey, maxItems),
      HomeWidget.saveWidgetData<bool>(widgetShowCountKey, showCount),
      HomeWidget.saveWidgetData<String>(
        'widget_hide_completed_before_date',
        todayKey,
      ),
    ]);

    await HomeWidget.updateWidget(androidName: _todoWidgetName);
    await HomeWidget.updateWidget(androidName: _dayPlanWidgetName);
  }

  static bool _readBool(String key, {required bool fallback}) {
    final raw = AppDatabase.settingsBox.get(key, defaultValue: fallback);
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    if (raw is num) return raw != 0;
    return fallback;
  }

  static int _readInt(String key, {required int fallback}) {
    final raw = AppDatabase.settingsBox.get(key, defaultValue: fallback);
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? fallback;
    if (raw is num) return raw.toInt();
    return fallback;
  }

  static String _dateKey(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }
}
