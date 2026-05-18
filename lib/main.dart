import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/service_locator.dart';
import 'presentation/screens/run_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/workouts_screen.dart';
import 'presentation/screens/comparison_screen.dart';
import 'infrastructure/background/foreground_task_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ForegroundTaskManager.initialize();
  setupServiceLocator();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yürük',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _requestBatteryOptimizationExemption();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool('battery_opt_asked') ?? false;
    if (alreadyAsked) return;

    final isIgnoring =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (isIgnoring) {
      await prefs.setBool('battery_opt_asked', true);
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Pil Optimizasyonu'),
        content: const Text(
          'Koşu sırasında GPS\'in sürekli çalışması için pil optimizasyonunun kapatılması gerekiyor.\n\n'
          'Açılan ekranda "Kısıtlama yok" seçeneğini seç.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool('battery_opt_asked', true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Daha Sonra'),
          ),
          FilledButton(
            onPressed: () async {
              await prefs.setBool('battery_opt_asked', true);
              if (ctx.mounted) Navigator.pop(ctx);
              FlutterForegroundTask.requestIgnoreBatteryOptimization();
            },
            child: const Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  final List<Widget> _screens = const [
    RunScreen(),
    WorkoutsScreen(),
    HistoryScreen(),
    ComparisonScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Koş',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Etkinlikler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Lab',
          ),
        ],
      ),
    );
  }
}
