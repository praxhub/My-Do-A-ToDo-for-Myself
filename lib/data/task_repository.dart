import 'dart:io';

import '../models/task_item.dart';
import '../services/widget_sync_service.dart';
import 'app_database.dart';

class TaskRepository {
  TaskRepository._();

  static TaskItem? getById(String id) {
    return AppDatabase.taskBox.get(id);
  }

  static List<TaskItem> allSorted() {
    final tasks = AppDatabase.taskBox.values.toList();
    tasks.sort((a, b) {
      final aDue = a.dueDate;
      final bDue = b.dueDate;
      if (aDue == null && bDue == null) {
        return a.createdAt.compareTo(b.createdAt);
      }
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      return aDue.compareTo(bDue);
    });
    return tasks;
  }

  static List<TaskItem> byKind(TaskKind kind) {
    return allSorted().where((task) => task.kind == kind).toList();
  }

  static List<TaskItem> todoAllUnfinished() {
    return byKind(TaskKind.todo).where((task) => !task.isCompleted).toList();
  }

  static List<TaskItem> dayPlanAll() {
    final tasks = byKind(TaskKind.dayPlan).toList();
    tasks.sort((a, b) {
      final priorityCmp = b.priority.index.compareTo(a.priority.index);
      if (priorityCmp != 0) return priorityCmp;
      final aDue = a.dueDate;
      final bDue = b.dueDate;
      if (aDue == null && bDue == null) {
        return a.createdAt.compareTo(b.createdAt);
      }
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      final dueCmp = aDue.compareTo(bDue);
      if (dueCmp != 0) return dueCmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    return tasks;
  }

  static List<TaskItem> dayPlanForDate(DateTime date) {
    return dayPlanAll().where((task) {
      final dueDate = task.dueDate;
      if (dueDate == null) return false;
      return dueDate.year == date.year &&
          dueDate.month == date.month &&
          dueDate.day == date.day;
    }).toList();
  }

  static List<TaskItem> todoByDate(DateTime date) {
    return byKind(TaskKind.todo).where((task) {
      final dueDate = task.dueDate;
      if (dueDate == null) return false;
      return dueDate.year == date.year &&
          dueDate.month == date.month &&
          dueDate.day == date.day;
    }).toList();
  }

  static List<TaskItem> byDate(DateTime date) {
    return allSorted().where((task) {
      final dueDate = task.dueDate;
      if (dueDate == null) return false;
      return dueDate.year == date.year &&
          dueDate.month == date.month &&
          dueDate.day == date.day;
    }).toList();
  }

  static Future<void> upsert(TaskItem task) async {
    await AppDatabase.taskBox.put(task.id, task);
    await WidgetSyncService.refreshTodayTasks();
  }

  static Future<void> toggleComplete(TaskItem task, bool value) async {
    task.isCompleted = value;
    task.completedAt = value ? DateTime.now() : null;
    await upsert(task);
  }

  static Future<void> delete(TaskItem task) async {
    await _deleteFileIfExists(task.imagePath);
    await _deleteFileIfExists(task.audioPath);
    await AppDatabase.taskBox.delete(task.id);
    await WidgetSyncService.refreshTodayTasks();
  }

  static Future<void> deleteAudio(TaskItem task) async {
    await _deleteFileIfExists(task.audioPath);
    task.audioPath = null;
    await upsert(task);
  }

  static Future<void> deleteImage(TaskItem task) async {
    await _deleteFileIfExists(task.imagePath);
    task.imagePath = null;
    await upsert(task);
  }

  static Future<void> _deleteFileIfExists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
