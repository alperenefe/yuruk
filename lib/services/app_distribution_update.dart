import 'package:firebase_app_distribution/firebase_app_distribution.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Distribution — uygulama icinden guncelleme.
abstract final class AppDistributionUpdate {
  static bool _firebaseReady = false;

  static Future<bool> ensureFirebase() async {
    if (_firebaseReady) {
      return true;
    }
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<AppUpdateResult> checkFromApp() async {
    if (!kReleaseMode) {
      return AppUpdateResult.debugBuild;
    }
    if (!await ensureFirebase()) {
      return AppUpdateResult.firebaseNotConfigured;
    }
    try {
      if (!await isTesterSignedIn()) {
        await signInTester();
      }
      final available = await isNewReleaseAvailable();
      if (!available) {
        return AppUpdateResult.upToDate;
      }
      await updateIfNewReleaseAvailable();
      return AppUpdateResult.updateStarted;
    } catch (_) {
      return AppUpdateResult.failed;
    }
  }
}

enum AppUpdateResult {
  upToDate,
  updateStarted,
  debugBuild,
  firebaseNotConfigured,
  failed,
}
