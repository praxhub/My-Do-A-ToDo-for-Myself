import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/app_database.dart';
import '../data/task_repository.dart';
import '../models/task_item.dart';
import 'add_edit_task_screen.dart';
import '../widgets/task_tile.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppDatabase.taskBox.listenable(),
      builder: (context, _, __) {
        final tasks = TaskRepository.byKind(TaskKind.todo);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tasks.length} total task(s)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddEditTaskScreen(initialKind: TaskKind.todo),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add ToDo'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('No ToDo yet.'))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskTile(
                          task: task,
                          onToggleComplete: (value) =>
                              TaskRepository.toggleComplete(task, value),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddEditTaskScreen(existingTask: task),
                            ),
                          ),
                          onDelete: () => TaskRepository.delete(task),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
