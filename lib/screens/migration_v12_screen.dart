import 'package:flutter/material.dart';

import '../services/migration_v12_service.dart';

class MigrationV12Screen extends StatefulWidget {
  const MigrationV12Screen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<MigrationV12Screen> createState() => _MigrationV12ScreenState();
}

class _MigrationV12ScreenState extends State<MigrationV12Screen> {
  bool _running = false;

  Future<void> _run(MigrationV12Strategy strategy) async {
    if (_running) return;
    setState(() => _running = true);
    await MigrationV12Service.run(strategy);
    if (!mounted) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My-Do v1.2 Migration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose how old tasks should map to ToDo and Day Plan. '
              'Daily Notes will be merged into Day Plan automatically.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _running
                  ? null
                  : () => _run(MigrationV12Strategy.moveAllToTodo),
              child: const Text('Move All Old Tasks To ToDo'),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: _running
                  ? null
                  : () => _run(MigrationV12Strategy.autoSplitByDueDate),
              child: const Text('Auto-split by due date'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _running
                  ? null
                  : () => _run(MigrationV12Strategy.skipForNow),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
