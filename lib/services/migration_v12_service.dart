import '../data/app_database.dart';
import '../data/daily_note_repository.dart';
import '../data/task_repository.dart';
import '../models/task_item.dart';
import 'widget_sync_service.dart';

enum MigrationV12Strategy { moveAllToTodo, autoSplitByDueDate, skipForNow }

class MigrationV12Service {
  MigrationV12Service._();

  static const completedKey = 'migration_v12_completed';

  static bool get isCompleted =>
      AppDatabase.settingsBox.get(completedKey, defaultValue: false) as bool;

  static Future<void> run(MigrationV12Strategy strategy) async {
    await _mergeDailyNotesIntoDayPlan();
    await _applyTaskKindStrategy(strategy);
    await AppDatabase.settingsBox.put(completedKey, true);
    await WidgetSyncService.refreshTodayTasks();
  }

  static Future<void> _mergeDailyNotesIntoDayPlan() async {
    final notes = DailyNoteRepository.all();
    if (notes.isEmpty) return;

    for (final note in notes) {
      final title = _noteTitle(note.content);
      final dayPlanTask = TaskItem(
        id: 'note_${note.id}',
        title: title,
        description: note.content.trim().isEmpty ? null : note.content.trim(),
        dueDate: DateTime(note.date.year, note.date.month, note.date.day, 9, 0),
        priority: TaskPriority.medium,
        kind: TaskKind.dayPlan,
        isCompleted: false,
        imagePath: note.imagePath,
        audioPath: null,
        createdAt: note.date,
      );
      await AppDatabase.taskBox.put(dayPlanTask.id, dayPlanTask);
    }
    await DailyNoteRepository.clearAll();
  }

  static Future<void> _applyTaskKindStrategy(
    MigrationV12Strategy strategy,
  ) async {
    if (strategy == MigrationV12Strategy.skipForNow) return;

    final tasks = TaskRepository.allSorted();
    for (final task in tasks) {
      if (task.id.startsWith('note_')) {
        task.kind = TaskKind.dayPlan;
      } else if (strategy == MigrationV12Strategy.moveAllToTodo) {
        task.kind = TaskKind.todo;
      } else {
        task.kind = task.dueDate == null ? TaskKind.todo : TaskKind.dayPlan;
      }
      await AppDatabase.taskBox.put(task.id, task);
    }
  }

  static String _noteTitle(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'Day Plan Note';
    final firstLine = trimmed.split('\n').first.trim();
    if (firstLine.isEmpty) return 'Day Plan Note';
    return firstLine.length > 60
        ? '${firstLine.substring(0, 60)}...'
        : firstLine;
  }
}
