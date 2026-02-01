import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/domain/entities/run_session.dart';
import 'package:yuruk/domain/entities/track_point.dart';

void main() {
  group('RunSession', () {
    test('should calculate average pace correctly', () {
      final session = RunSession(
        id: 'test-1',
        startTime: DateTime.now(),
        status: RunStatus.running,
        trackPoints: const [],
        totalDistance: 1000,
        elapsedTime: const Duration(minutes: 5),
      );

      expect(session.averagePaceMinPerKm, 5.0);
    });

    test('should return 0 pace when distance < 100m', () {
      final session = RunSession(
        id: 'test-1',
        startTime: DateTime.now(),
        status: RunStatus.running,
        trackPoints: const [],
        totalDistance: 50,
        elapsedTime: const Duration(minutes: 5),
      );

      expect(session.averagePaceMinPerKm, 0);
    });

    test('should format pace correctly', () {
      final session = RunSession(
        id: 'test-1',
        startTime: DateTime.now(),
        status: RunStatus.running,
        trackPoints: const [],
        totalDistance: 1000,
        elapsedTime: const Duration(minutes: 5, seconds: 30),
      );

      expect(session.averagePaceFormatted, '05:30');
    });

    test('should return "--:--" when distance < 100m', () {
      final session = RunSession(
        id: 'test-1',
        startTime: DateTime.now(),
        status: RunStatus.running,
        trackPoints: const [],
        totalDistance: 50,
        elapsedTime: const Duration(minutes: 5),
      );

      expect(session.averagePaceFormatted, '--:--');
    });

    test('copyWith should create new instance with updated values', () {
      final session = RunSession(
        id: 'test-1',
        startTime: DateTime.now(),
        status: RunStatus.running,
        trackPoints: const [],
        totalDistance: 100,
        elapsedTime: const Duration(minutes: 1),
      );

      final updated = session.copyWith(
        totalDistance: 200,
        status: RunStatus.stopped,
      );

      expect(updated.totalDistance, 200);
      expect(updated.status, RunStatus.stopped);
      expect(updated.id, session.id);
      expect(updated.elapsedTime, session.elapsedTime);
    });
  });
}
