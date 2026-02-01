import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/domain/entities/run_session.dart';
import 'package:yuruk/domain/entities/track_point.dart';
import 'package:yuruk/domain/usecases/update_run_session.dart';

void main() {
  late UpdateRunSession updateRunSession;

  setUp(() {
    updateRunSession = UpdateRunSession();
  });

  group('UpdateRunSession', () {
    test('should add new accurate point to session', () {
      final startTime = DateTime.now();
      final session = RunSession(
        id: 'test-1',
        startTime: startTime,
        status: RunStatus.running,
        trackPoints: const [],
        totalDistance: 0,
        elapsedTime: Duration.zero,
      );

      final newPoint = TrackPoint(
        latitude: 41.0082,
        longitude: 28.9784,
        altitude: 100,
        accuracy: 10,
        speed: 3.0,
        timestamp: startTime.add(const Duration(seconds: 2)),
      );

      final updated = updateRunSession.execute(session, newPoint);

      expect(updated.trackPoints.length, 1);
      expect(updated.trackPoints.first, newPoint);
    });

    test('should reject inaccurate points', () {
      final startTime = DateTime.now();
      final session = RunSession(
        id: 'test-1',
        startTime: startTime,
        status: RunStatus.running,
        trackPoints: const [],
        totalDistance: 0,
        elapsedTime: Duration.zero,
      );

      final inaccuratePoint = TrackPoint(
        latitude: 41.0082,
        longitude: 28.9784,
        altitude: 100,
        accuracy: 50,
        speed: 3.0,
        timestamp: startTime.add(const Duration(seconds: 2)),
      );

      final updated = updateRunSession.execute(session, inaccuratePoint);

      expect(updated.trackPoints.length, 0);
    });

    test('should reject points with unreasonable speed', () {
      final startTime = DateTime.now();
      final session = RunSession(
        id: 'test-1',
        startTime: startTime,
        status: RunStatus.running,
        trackPoints: const [],
        totalDistance: 0,
        elapsedTime: Duration.zero,
      );

      final fastPoint = TrackPoint(
        latitude: 41.0082,
        longitude: 28.9784,
        altitude: 100,
        accuracy: 10,
        speed: 30.0,
        timestamp: startTime.add(const Duration(seconds: 2)),
      );

      final updated = updateRunSession.execute(session, fastPoint);

      expect(updated.trackPoints.length, 0);
    });

    test('should calculate distance and update session', () {
      final startTime = DateTime.now();
      final firstPoint = TrackPoint(
        latitude: 41.0082,
        longitude: 28.9784,
        altitude: 100,
        accuracy: 10,
        speed: 3.0,
        timestamp: startTime,
      );

      final session = RunSession(
        id: 'test-1',
        startTime: startTime,
        status: RunStatus.running,
        trackPoints: [firstPoint],
        totalDistance: 0,
        elapsedTime: Duration.zero,
      );

      final secondPoint = TrackPoint(
        latitude: 41.0092,
        longitude: 28.9794,
        altitude: 100,
        accuracy: 10,
        speed: 3.0,
        timestamp: startTime.add(const Duration(seconds: 10)),
      );

      final updated = updateRunSession.execute(session, secondPoint);

      expect(updated.trackPoints.length, 2);
      expect(updated.totalDistance, greaterThan(0));
      expect(updated.elapsedTime.inSeconds, 10);
    });

    test('should not update stopped session', () {
      final startTime = DateTime.now();
      final session = RunSession(
        id: 'test-1',
        startTime: startTime,
        status: RunStatus.stopped,
        trackPoints: const [],
        totalDistance: 0,
        elapsedTime: Duration.zero,
      );

      final newPoint = TrackPoint(
        latitude: 41.0082,
        longitude: 28.9784,
        altitude: 100,
        accuracy: 10,
        speed: 3.0,
        timestamp: startTime.add(const Duration(seconds: 2)),
      );

      final updated = updateRunSession.execute(session, newPoint);

      expect(updated.trackPoints.length, 0);
      expect(updated.status, RunStatus.stopped);
    });
  });
}
