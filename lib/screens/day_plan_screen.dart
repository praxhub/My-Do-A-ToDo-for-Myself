import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/app_database.dart';
import '../data/task_repository.dart';
import '../models/task_item.dart';
import '../widgets/task_tile.dart';
import 'add_edit_task_screen.dart';

enum DayPlanFilter { today, selectedDate, all }

class DayPlanScreen extends StatefulWidget {
  const DayPlanScreen({super.key});

  @override
  State<DayPlanScreen> createState() => _DayPlanScreenState();
}

class _DayPlanScreenState extends State<DayPlanScreen> {
  DayPlanFilter _filter = DayPlanFilter.today;
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _filter = DayPlanFilter.selectedDate;
    });
  }

  List<TaskItem> _buildTasks() {
    if (_filter == DayPlanFilter.all) {
      return TaskRepository.dayPlanAll();
    }
    if (_filter == DayPlanFilter.selectedDate) {
      return TaskRepository.dayPlanForDate(_selectedDate);
    }
    return TaskRepository.dayPlanForDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppDatabase.taskBox.listenable(),
      builder: (context, _, __) {
        final tasks = _buildTasks();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Today'),
                          selected: _filter == DayPlanFilter.today,
                          onSelected: (_) =>
                              setState(() => _filter = DayPlanFilter.today),
                        ),
                        ChoiceChip(
                          label: const Text('Selected'),
                          selected: _filter == DayPlanFilter.selectedDate,
                          onSelected: (_) => _pickDate(),
                        ),
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _filter == DayPlanFilter.all,
                          onSelected: (_) =>
                              setState(() => _filter = DayPlanFilter.all),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditTaskScreen(
                          initialKind: TaskKind.dayPlan,
                          initialDueDate: DateTime.now(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('No Day Plan items yet.'))
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
