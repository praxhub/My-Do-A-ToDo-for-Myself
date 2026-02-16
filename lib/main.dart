import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'data/app_database.dart';
import 'screens/home_shell.dart';
import 'services/widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.init();

  final themeController = ThemeController();
  await themeController.load();
  await WidgetSyncService.refreshTodayTasks();

  runApp(MyTodoApp(themeController: themeController));
}

class MyTodoApp extends StatelessWidget {
  const MyTodoApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'My-Do',
          themeMode: themeController.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0E6E6E),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF9ED9D9),
            ),
            useMaterial3: true,
          ),
          home: HomeShell(themeController: themeController),
        );
      },
    );
  }
}
