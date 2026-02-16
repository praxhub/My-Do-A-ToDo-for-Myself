import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/app_database.dart';
import '../data/task_repository.dart';
import '../models/task_item.dart';
import 'add_edit_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppDatabase.taskBox.listenable(),
      builder: (context, _, __) {
        final selectedTasks = TaskRepository.byDate(_selectedDay);

        return Column(
          children: [
            TableCalendar<TaskItem>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2050),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: (day) => TaskRepository.byDate(day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tasks for ${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditTaskScreen(initialDueDate: _selectedDay),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: selectedTasks.isEmpty
                  ? const Center(child: Text('No tasks for this date'))
                  : ListView.builder(
                      itemCount: selectedTasks.length,
                      itemBuilder: (context, index) {
                        final task = selectedTasks[index];
                        return ListTile(
                          title: Text(task.title),
                          subtitle: Text(task.priority.name.toUpperCase()),
                          trailing: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) => TaskRepository.toggleComplete(
                              task,
                              value ?? false,
                            ),
                          ),
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
