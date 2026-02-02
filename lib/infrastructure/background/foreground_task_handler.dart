import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Handler for foreground task (background GPS tracking)
@pragma('vm:entry-point')
void startForegroundTask() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

class ForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🚀 Foreground task started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // This is called every interval
    // GPS tracking continues in the main app
    print('⏱️ Foreground task running...');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('🛑 Foreground task stopped');
  }
}

/// Configure and initialize foreground service
class ForegroundTaskManager {
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'yuruk_tracking',
        channelName: 'Koşu Takibi',
        channelDescription: 'GPS ile koşu takibi yapılıyor',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // Every 5 seconds
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<ServiceRequestResult> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return await FlutterForegroundTask.restartService();
    } else {
      return await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Yürük - Koşu Devam Ediyor',
        notificationText: 'GPS ile konumunuz izleniyor',
        callback: startForegroundTask,
      );
    }
  }

  static Future<ServiceRequestResult> stopService() async {
    return await FlutterForegroundTask.stopService();
  }

  static Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }
}
