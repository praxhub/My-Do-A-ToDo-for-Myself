import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import 'calendar_screen.dart';
import 'daily_notes_screen.dart';
import 'day_plan_screen.dart';
import 'settings_screen.dart';
import 'task_list_screen.dart';

enum HomeTab { todo, dayPlan, journal, calendar, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.themeController,
    this.initialTab = HomeTab.todo,
  });

  final ThemeController themeController;
  final HomeTab initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = HomeTab.values.indexOf(widget.initialTab);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const TaskListScreen(),
      const DayPlanScreen(),
      const DailyNotesScreen(),
      const CalendarScreen(),
      const SettingsScreen(),
    ];

    final titles = ['ToDo', 'Day Plan', 'Journal', 'Calendar', 'Settings'];

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
          NavigationDestination(icon: Icon(Icons.checklist), label: 'ToDo'),
          NavigationDestination(
            icon: Icon(Icons.view_day_outlined),
            label: 'Day Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onDestinationSelected: (idx) => setState(() => _index = idx),
      ),
    );
  }
}
