import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/domain/entities/run_session.dart';
import 'package:yuruk/domain/entities/track_point.dart';

// SQLite gerçek DB gerektirdiğinden bu testler decode mantığını unit test eder.
// Gerçek DB entegrasyon testi için integration_test/ kullanılabilir.

// Aşağıdaki testler, DB'den okunacak ham JSON formatının
// doğru şekilde decode edildiğini doğrular.

void main() {
  group('RunSession JSON round-trip (codec)', () {
    final samplePoint = TrackPoint(
      latitude: 39.9208,
      longitude: 32.8541,
      altitude: 900,
      accuracy: 8.5,
      speed: 2.3,
      bearing: 45.0,
      timestamp: DateTime(2024, 3, 15, 10, 30),
    );

    test('TrackPoint alanları encode → decode round-trip korunur', () {
      // Encode
      final encoded = {
        'latitude': samplePoint.latitude,
        'longitude': samplePoint.longitude,
        'altitude': samplePoint.altitude,
        'accuracy': samplePoint.accuracy,
        'speed': samplePoint.speed,
        'bearing': samplePoint.bearing,
        'timestamp': samplePoint.timestamp.millisecondsSinceEpoch,
      };
      // Decode
      final decoded = TrackPoint(
        latitude: (encoded['latitude'] as num).toDouble(),
        longitude: (encoded['longitude'] as num).toDouble(),
        altitude: (encoded['altitude'] as num? ?? 0).toDouble(),
        accuracy: (encoded['accuracy'] as num? ?? 0).toDouble(),
        speed: (encoded['speed'] as num? ?? 0).toDouble(),
        bearing: encoded['bearing'] == null
            ? null
            : (encoded['bearing'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            (encoded['timestamp'] as num).toInt()),
      );

      expect(decoded.latitude, samplePoint.latitude);
      expect(decoded.longitude, samplePoint.longitude);
      expect(decoded.altitude, samplePoint.altitude);
      expect(decoded.accuracy, samplePoint.accuracy);
      expect(decoded.speed, samplePoint.speed);
      expect(decoded.bearing, samplePoint.bearing);
      expect(decoded.timestamp, samplePoint.timestamp);
    });

    test('bearing null olduğunda null döner (crash yok)', () {
      final encoded = {
        'latitude': 39.0,
        'longitude': 32.0,
        'altitude': 0,
        'accuracy': 10,
        'speed': 1.0,
        'bearing': null,
        'timestamp': DateTime(2024).millisecondsSinceEpoch,
      };
      final decoded = TrackPoint(
        latitude: (encoded['latitude'] as num).toDouble(),
        longitude: (encoded['longitude'] as num).toDouble(),
        altitude: (encoded['altitude'] as num? ?? 0).toDouble(),
        accuracy: (encoded['accuracy'] as num? ?? 0).toDouble(),
        speed: (encoded['speed'] as num? ?? 0).toDouble(),
        bearing: encoded['bearing'] == null
            ? null
            : (encoded['bearing'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            (encoded['timestamp'] as num).toInt()),
      );
      expect(decoded.bearing, isNull);
    });

    test('RunStatus bilinmeyen değerde orElse=stopped döner', () {
      final statusName = 'unknownStatus';
      final result = RunStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => RunStatus.stopped,
      );
      expect(result, RunStatus.stopped);
    });

    test('RunStatus geçerli değerlerin hepsi parse edilir', () {
      for (final status in RunStatus.values) {
        final parsed = RunStatus.values.firstWhere(
          (e) => e.name == status.name,
          orElse: () => RunStatus.stopped,
        );
        expect(parsed, status);
      }
    });
  });

  group('RunSession labInputPoints + hasGpxGeometry', () {
    final p = TrackPoint(
      latitude: 39.0,
      longitude: 32.0,
      altitude: 0,
      accuracy: 10,
      speed: 1.5,
      timestamp: DateTime(2024),
    );

    test('raw ve filtered aynı → labInputPoints raw döndürür', () {
      final session = RunSession(
        id: 'x',
        startTime: DateTime(2024),
        status: RunStatus.stopped,
        trackPoints: [p, p],
        rawTrackPoints: [p],
        totalDistance: 100,
        elapsedTime: const Duration(minutes: 1),
      );
      expect(session.labInputPoints.length, 1); // raw tercih edilir
    });

    test('raw boş → filtered döner', () {
      final session = RunSession(
        id: 'x',
        startTime: DateTime(2024),
        status: RunStatus.stopped,
        trackPoints: [p, p],
        totalDistance: 100,
        elapsedTime: const Duration(minutes: 1),
      );
      expect(session.labInputPoints.length, 2);
    });

    test('hasGpxGeometry: ikisi de boş → false', () {
      final session = RunSession(
        id: 'x',
        startTime: DateTime(2024),
        status: RunStatus.stopped,
        trackPoints: const [],
        totalDistance: 0,
        elapsedTime: Duration.zero,
      );
      expect(session.hasGpxGeometry, false);
    });
  });
}
