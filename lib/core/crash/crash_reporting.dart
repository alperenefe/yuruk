import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Uygulama genelinde hata yakalama. SENTRY_DSN tanımlı değilse sessizce atlanır.
class CrashReporting {
  CrashReporting._();

  static bool get isEnabled {
    const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    return dsn.isNotEmpty;
  }

  static Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (!isEnabled) {
      if (kDebugMode) {
        debugPrint('CrashReporting (no DSN): $exception');
        if (hint != null) debugPrint('  hint: $hint');
      }
      return;
    }
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (hint != null) {
          scope.setTag('hint', hint);
        }
      },
    );
  }

  static Future<void> captureMessage(String message, {SentryLevel? level}) async {
    if (!isEnabled) return;
    await Sentry.captureMessage(message, level: level ?? SentryLevel.info);
  }
}
