import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_item.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onTap,
    required this.onDelete,
  });

  final TaskItem task;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final due = task.dueDate == null
        ? 'No due date'
        : DateFormat.yMMMd().add_jm().format(task.dueDate!);

    final priorityColor = switch (task.priority) {
      TaskPriority.low => Colors.green,
      TaskPriority.medium => Colors.orange,
      TaskPriority.high => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) => onToggleComplete(value ?? false),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Theme.of(context).disabledColor : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(due),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(task.priority.name.toUpperCase()),
                  backgroundColor: priorityColor.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: priorityColor.withValues(alpha: 0.35),
                  ),
                  labelStyle: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w700,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                if (task.imagePath != null &&
                    File(task.imagePath!).existsSync())
                  const Icon(Icons.image, size: 18),
                if (task.audioPath != null &&
                    File(task.audioPath!).existsSync())
                  const Icon(Icons.mic, size: 18),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
