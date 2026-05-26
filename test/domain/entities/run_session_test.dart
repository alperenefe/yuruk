import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/domain/entities/run_session.dart';
import 'package:yuruk/domain/entities/track_point.dart';
import 'package:yuruk/domain/entities/named_track_segment.dart';

RunSession _session({
  double distance = 1000,
  Duration elapsed = const Duration(minutes: 5),
  List<TrackPoint> trackPoints = const [],
  List<TrackPoint> rawTrackPoints = const [],
}) {
  return RunSession(
    id: 'test-1',
    startTime: DateTime(2024),
    status: RunStatus.running,
    trackPoints: trackPoints,
    rawTrackPoints: rawTrackPoints,
    totalDistance: distance,
    elapsedTime: elapsed,
  );
}

TrackPoint _pt(double lat, double lng) => TrackPoint(
      latitude: lat,
      longitude: lng,
      altitude: 0,
      accuracy: 10,
      speed: 1.5,
      timestamp: DateTime(2024),
    );

void main() {
  group('RunSession.averagePaceMinPerKm', () {
    test('1000m/5dk → 5.0 min/km', () {
      expect(_session(distance: 1000, elapsed: const Duration(minutes: 5)).averagePaceMinPerKm, 5.0);
    });

    test('50m altındayken 0 döner', () {
      expect(_session(distance: 30).averagePaceMinPerKm, 0.0);
    });
  });

  group('RunSession.averagePaceFormatted', () {
    test('5:30 pace doğru formatlanır', () {
      final s = _session(distance: 1000, elapsed: const Duration(minutes: 5, seconds: 30));
      expect(s.averagePaceFormatted, '05:30');
    });

    test('50m altında --:-- döner', () {
      expect(_session(distance: 30).averagePaceFormatted, '--:--');
    });

    test('formatlanmış pace asla "XX:60" içermez', () {
      // Farklı mesafe/süre kombinasyonlarında saniye değeri 0..59 aralığında kalmalı
      final cases = [
        (1000.0, const Duration(minutes: 5, seconds: 29)),
        (1000.0, const Duration(minutes: 5, seconds: 59)),
        (500.0, const Duration(minutes: 3, seconds: 0)),
        (1500.0, const Duration(minutes: 7, seconds: 30)),
        (3000.0, const Duration(minutes: 14, seconds: 59)),
      ];
      for (final (dist, elapsed) in cases) {
        final s = RunSession(
          id: 'p',
          startTime: DateTime(2024),
          status: RunStatus.running,
          trackPoints: const [],
          totalDistance: dist,
          elapsedTime: elapsed,
        );
        final formatted = s.averagePaceFormatted;
        if (formatted != '--:--') {
          final parts = formatted.split(':');
          expect(parts.length, 2, reason: 'Format MM:SS olmalı');
          final secs = int.parse(parts[1]);
          expect(secs, lessThan(60), reason: 'Saniye 60\'a eşit veya büyük olamaz: $formatted');
        }
      }
    });
  });

  group('RunSession.labInputPoints', () {
    test('rawTrackPoints varsa rawTrackPoints döner', () {
      final raw = [_pt(1, 1)];
      final filtered = [_pt(2, 2), _pt(3, 3)];
      final s = _session(trackPoints: filtered, rawTrackPoints: raw);
      expect(s.labInputPoints, raw);
    });

    test('rawTrackPoints boşsa trackPoints döner', () {
      final filtered = [_pt(2, 2), _pt(3, 3)];
      final s = _session(trackPoints: filtered);
      expect(s.labInputPoints, filtered);
    });

    test('ikisi de boşsa boş liste döner', () {
      expect(_session().labInputPoints, isEmpty);
    });
  });

  group('RunSession.hasGpxGeometry', () {
    test('rawTrackPoints varsa true', () {
      expect(_session(rawTrackPoints: [_pt(1, 1)]).hasGpxGeometry, true);
    });

    test('trackPoints varsa true', () {
      expect(_session(trackPoints: [_pt(1, 1)]).hasGpxGeometry, true);
    });

    test('filterExportTracks içinde nokta varsa true', () {
      final s = RunSession(
        id: 'x',
        startTime: DateTime(2024),
        status: RunStatus.stopped,
        trackPoints: const [],
        totalDistance: 0,
        elapsedTime: Duration.zero,
        filterExportTracks: [
          NamedTrackSegment(name: 'A', points: [_pt(1, 1)])
        ],
      );
      expect(s.hasGpxGeometry, true);
    });

    test('hiçbir şey yoksa false', () {
      expect(_session().hasGpxGeometry, false);
    });
  });

  group('RunSession.copyWith', () {
    test('belirtilen alanları günceller, diğerleri korunur', () {
      final original = _session(distance: 100, elapsed: const Duration(minutes: 1));
      final updated = original.copyWith(totalDistance: 200, status: RunStatus.stopped);
      expect(updated.totalDistance, 200);
      expect(updated.status, RunStatus.stopped);
      expect(updated.id, original.id);
      expect(updated.elapsedTime, original.elapsedTime);
    });
  });
}
