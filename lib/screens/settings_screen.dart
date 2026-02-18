import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../services/widget_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAllUnfinished = true;
  bool _showCount = true;
  int _maxItems = 20;

  @override
  void initState() {
    super.initState();
    _showAllUnfinished = _readBool(
      WidgetSyncService.widgetShowAllUnfinishedKey,
      true,
    );
    _showCount = _readBool(WidgetSyncService.widgetShowCountKey, true);
    _maxItems = _readInt(WidgetSyncService.widgetMaxItemsKey, 20).clamp(1, 100);
  }

  Future<void> _toggleWidgetScope(bool value) async {
    setState(() => _showAllUnfinished = value);
    await AppDatabase.settingsBox.put(
      WidgetSyncService.widgetShowAllUnfinishedKey,
      value,
    );
    await WidgetSyncService.refreshTodayTasks();
  }

  Future<void> _toggleShowCount(bool value) async {
    setState(() => _showCount = value);
    await AppDatabase.settingsBox.put(
      WidgetSyncService.widgetShowCountKey,
      value,
    );
    await WidgetSyncService.refreshTodayTasks();
  }

  Future<void> _setMaxItems(double value) async {
    final rounded = value.round().clamp(1, 100);
    setState(() => _maxItems = rounded);
    await AppDatabase.settingsBox.put(
      WidgetSyncService.widgetMaxItemsKey,
      rounded,
    );
    await WidgetSyncService.refreshTodayTasks();
  }

  bool _readBool(String key, bool fallback) {
    final raw = AppDatabase.settingsBox.get(key, defaultValue: fallback);
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    if (raw is num) return raw != 0;
    return fallback;
  }

  int _readInt(String key, int fallback) {
    final raw = AppDatabase.settingsBox.get(key, defaultValue: fallback);
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? fallback;
    if (raw is num) return raw.toInt();
    return fallback;
  }

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
        SwitchListTile(
          value: _showAllUnfinished,
          onChanged: _toggleWidgetScope,
          title: const Text('Widgets: Show All Unfinished'),
          subtitle: const Text(
            'ON: past/present/future unfinished tasks. OFF: today only.',
          ),
        ),
        const Divider(),
        SwitchListTile(
          value: _showCount,
          onChanged: _toggleShowCount,
          title: const Text('Show Task Count'),
          subtitle: const Text('Display or hide the count line in widgets.'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.format_list_numbered),
          title: const Text('Max Items In Widget'),
          subtitle: Text('$_maxItems item(s)'),
        ),
        Slider(
          value: _maxItems.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          label: '$_maxItems',
          onChanged: _setMaxItems,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.widgets_outlined),
          title: const Text('Refresh Home Widget'),
          subtitle: const Text(
            'Apply latest task data and theme to Android widget.',
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
