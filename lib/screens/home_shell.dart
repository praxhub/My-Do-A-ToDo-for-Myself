import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import 'calendar_screen.dart';
import 'daily_notes_screen.dart';
import 'settings_screen.dart';
import 'task_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const TaskListScreen(),
      const CalendarScreen(),
      const DailyNotesScreen(),
      const SettingsScreen(),
    ];

    final titles = ['Tasks', 'Calendar', 'Daily Notes', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            onPressed: widget.themeController.toggleTheme,
            tooltip: 'Toggle theme',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return RotationTransition(turns: animation, child: child);
              },
              child: widget.themeController.isDarkMode
                  ? const Icon(Icons.dark_mode, key: ValueKey('dark'))
                  : const Icon(Icons.light_mode, key: ValueKey('light')),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onDestinationSelected: (idx) => setState(() => _index = idx),
      ),
    );
  }
}
