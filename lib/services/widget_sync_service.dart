import 'package:home_widget/home_widget.dart';

import '../data/task_repository.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static const _androidWidgetName = 'TodayTaskWidgetProvider';

  static Future<void> refreshTodayTasks() async {
    final now = DateTime.now();
    final todayTasks = TaskRepository.byDate(
      now,
    ).where((task) => !task.isCompleted).toList();

    final topThree = todayTasks
        .take(3)
        .map((task) => '- ${task.title}')
        .join('\n');

    await HomeWidget.saveWidgetData<int>('today_task_count', todayTasks.length);
    await HomeWidget.saveWidgetData<String>(
      'today_task_titles',
      topThree.isEmpty ? 'No tasks due today' : topThree,
    );

    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
