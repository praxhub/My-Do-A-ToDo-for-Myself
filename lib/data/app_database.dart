import 'package:hive_flutter/hive_flutter.dart';

import '../models/daily_note.dart';
import '../models/task_item.dart';

class AppDatabase {
  static const String tasksBoxName = 'tasks';
  static const String notesBoxName = 'daily_notes';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyNoteAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TaskKindAdapter());
    }

    await Future.wait([
      Hive.openBox<TaskItem>(tasksBoxName),
      Hive.openBox<DailyNote>(notesBoxName),
      Hive.openBox(settingsBoxName),
    ]);
  }

  static Box<TaskItem> get taskBox => Hive.box<TaskItem>(tasksBoxName);

  static Box<DailyNote> get noteBox => Hive.box<DailyNote>(notesBoxName);

  static Box get settingsBox => Hive.box(settingsBoxName);
}
