import 'package:flutter/material.dart';

import '../data/task_repository.dart';

class WidgetQuickEditScreen extends StatefulWidget {
  const WidgetQuickEditScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<WidgetQuickEditScreen> createState() => _WidgetQuickEditScreenState();
}

class _WidgetQuickEditScreenState extends State<WidgetQuickEditScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    final task = TaskRepository.getById(widget.taskId);
    if (task != null) {
      _controller.text = task.title;
      _isReady = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final task = TaskRepository.getById(widget.taskId);
    if (task == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    task.title = _controller.text.trim();
    await TaskRepository.upsert(task);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quick Edit Task')),
        body: const Center(child: Text('Task not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Task'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Task is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save Task'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
