import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:uuid/uuid.dart';

import 'controllers/theme_controller.dart';
import 'data/app_database.dart';
import 'data/task_repository.dart';
import 'models/task_item.dart';
import 'screens/add_edit_task_screen.dart';
import 'screens/home_shell.dart';
import 'services/widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.registerInteractivityCallback(backgroundWidgetCallback);
  await AppDatabase.init();

  final themeController = ThemeController();
  await themeController.load();
  await WidgetSyncService.refreshTodayTasks();

  runApp(MyTodoApp(themeController: themeController));
}

@pragma('vm:entry-point')
Future<void> backgroundWidgetCallback(Uri? uri) async {
  if (uri == null) return;
  if (kDebugMode) {
    debugPrint('[WidgetBackground] uri=$uri');
  }

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await AppDatabase.init();

  final action = uri.queryParameters['action'];
  final taskId = uri.queryParameters['taskId'];
  final quickTitle =
      uri.queryParameters['task'] ?? uri.queryParameters['title'];
  final kindValue = uri.queryParameters['kind'];
  final dueMillis = int.tryParse(uri.queryParameters['dueMillis'] ?? '');
  final priority = _parsePriority(uri.queryParameters['priority']);

  if (action == 'add_quick' &&
      quickTitle != null &&
      quickTitle.trim().isNotEmpty) {
    final task = TaskItem(
      id: const Uuid().v4(),
      title: quickTitle.trim(),
      kind: kindValue == 'dayPlan' ? TaskKind.dayPlan : TaskKind.todo,
      dueDate: dueMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(dueMillis)
          : (kindValue == 'dayPlan' ? DateTime.now() : null),
      createdAt: DateTime.now(),
      priority: priority,
    );
    await TaskRepository.upsert(task);
    return;
  }

  if (taskId == null || taskId.isEmpty) {
    await WidgetSyncService.refreshTodayTasks();
    return;
  }

  final task = TaskRepository.getById(taskId);
  if (task == null) {
    if (kDebugMode) {
      debugPrint('[WidgetBackground] missing task id=$taskId');
    }
    await WidgetSyncService.refreshTodayTasks();
    return;
  }

  if (action == 'toggle') {
    await TaskRepository.toggleComplete(task, !task.isCompleted);
  } else if (action == 'delete') {
    await TaskRepository.delete(task);
  } else {
    await WidgetSyncService.refreshTodayTasks();
  }
}

class MyTodoApp extends StatefulWidget {
  const MyTodoApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<MyTodoApp> createState() => _MyTodoAppState();
}

class _MyTodoAppState extends State<MyTodoApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _widgetClickSubscription;
  String? _lastHandledUri;
  DateTime? _lastHandledAt;
  Uri? _pendingUri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupWidgetLaunchHandlers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetSyncService.refreshTodayTasks();
    }
  }

  Future<void> _setupWidgetLaunchHandlers() async {
    final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
    await _handleWidgetUri(initial);

    _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
      _handleWidgetUri(uri);
    });
  }

  Future<void> _handleWidgetUri(Uri? uri) async {
    if (uri == null) return;
    if (kDebugMode) {
      debugPrint('[WidgetAction] uri=$uri');
    }
    final now = DateTime.now();
    if (_lastHandledUri == uri.toString() &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastHandledUri = uri.toString();
    _lastHandledAt = now;

    final action = uri.queryParameters['action'];
    final taskId = uri.queryParameters['taskId'];
    final quickTitle =
        uri.queryParameters['task'] ?? uri.queryParameters['title'];
    final kindValue = uri.queryParameters['kind'];
    final dueMillis = int.tryParse(uri.queryParameters['dueMillis'] ?? '');
    final priority = _parsePriority(uri.queryParameters['priority']);
    final target = uri.queryParameters['target'];

    if (action == 'open') {
      final tab = switch (target) {
        'dayplan' => HomeTab.dayPlan,
        'journal' => HomeTab.journal,
        'calendar' => HomeTab.calendar,
        'settings' => HomeTab.settings,
        _ => HomeTab.todo,
      };
      final nav = _navigatorKey.currentState;
      if (nav != null) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeShell(
              themeController: widget.themeController,
              initialTab: tab,
            ),
          ),
          (_) => false,
        );
      }
      await WidgetSyncService.refreshTodayTasks();
      return;
    }

    if ((action == 'edit' || action == 'edit_title') &&
        taskId != null &&
        taskId.isNotEmpty) {
      final task = TaskRepository.getById(taskId);
      if (task == null) return;

      final nav = _navigatorKey.currentState;
      if (nav == null) {
        _pendingUri = uri;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final pending = _pendingUri;
          _pendingUri = null;
          _handleWidgetUri(pending);
        });
        return;
      }
      await nav.push(
        MaterialPageRoute(
          builder: (_) => AddEditTaskScreen(existingTask: task),
        ),
      );
      await WidgetSyncService.refreshTodayTasks();
      return;
    }

    if (action == 'add_quick' &&
        quickTitle != null &&
        quickTitle.trim().isNotEmpty) {
      final task = TaskItem(
        id: const Uuid().v4(),
        title: quickTitle.trim(),
        kind: kindValue == 'dayPlan' ? TaskKind.dayPlan : TaskKind.todo,
        dueDate: dueMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(dueMillis)
            : (kindValue == 'dayPlan' ? DateTime.now() : null),
        createdAt: DateTime.now(),
        priority: priority,
      );
      await TaskRepository.upsert(task);
      return;
    }

    if (action == 'open_add') {
      final nav = _navigatorKey.currentState;
      if (nav == null) return;
      await nav.push(
        MaterialPageRoute(
          builder: (_) => AddEditTaskScreen(
            initialKind: kindValue == 'dayPlan'
                ? TaskKind.dayPlan
                : TaskKind.todo,
            initialDueDate: kindValue == 'dayPlan' ? DateTime.now() : null,
          ),
        ),
      );
      await WidgetSyncService.refreshTodayTasks();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          title: 'My-Do',
          themeMode: widget.themeController.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0E6E6E),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: const Color(0xFF000000),
            canvasColor: const Color(0xFF000000),
            cardColor: const Color(0xFF0A0A0A),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF22D3EE),
              secondary: Color(0xFF14B8A6),
              surface: Color(0xFF0A0A0A),
              onSurface: Color(0xFFF5F5F5),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF000000),
              foregroundColor: Color(0xFFFFFFFF),
            ),
          ),
          home: SplashGate(themeController: widget.themeController),
        );
      },
    );
  }
}

TaskPriority _parsePriority(String? rawPriority) {
  switch (rawPriority?.toLowerCase()) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    default:
      return TaskPriority.medium;
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _showHome = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return HomeShell(themeController: widget.themeController);
    }

    final isDark = widget.themeController.isDarkMode;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF2F6FA), Color(0xFFE6EEF4)],
                ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                isDark
                    ? 'assets/splash_logo_dark.png'
                    : 'assets/splash_logo_light.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 16),
              Text(
                'My-Do',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
