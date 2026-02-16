import 'package:flutter/material.dart';

import '../services/widget_sync_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.offline_bolt),
          title: Text('Offline-first'),
          subtitle: Text('All data is stored locally on device.'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.widgets_outlined),
          title: const Text('Refresh Home Widget'),
          subtitle: const Text(
            'Update today task count/list on Android widget.',
          ),
          onTap: () async {
            await WidgetSyncService.refreshTodayTasks();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Widget refreshed')));
            }
          },
        ),
      ],
    );
  }
}
