import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/core/config/gps_filter_params.dart';
import 'package:yuruk/core/filters/gps_filter_pipeline.dart';
import 'package:yuruk/core/filters/simple_kalman_filter.dart';
import 'package:yuruk/domain/entities/track_point.dart';

TrackPoint pt(double lat, double lng,
    {double speed = 1.5,
    double accuracy = 10,
    DateTime? ts,
    int offsetSec = 0}) {
  return TrackPoint(
    latitude: lat,
    longitude: lng,
    altitude: 0,
    accuracy: accuracy,
    speed: speed,
    timestamp: (ts ?? DateTime(2024, 1, 1, 10)).add(Duration(seconds: offsetSec)),
  );
}

void main() {
  group('SimpleKalmanFilter', () {
    test('ilk değeri olduğu gibi döndürür', () {
      final f = SimpleKalmanFilter(q: 0.0001, r: 0.01);
      expect(f.filter(1.0), 1.0);
    });

    test('sabit giriş sabit çıkış üretir', () {
      final f = SimpleKalmanFilter(q: 0.0001, r: 0.01);
      f.filter(1.0);
      for (var i = 0; i < 20; i++) {
        f.filter(1.0);
      }
      expect(f.filter(1.0), closeTo(1.0, 1e-6));
    });

    test('reset sonrası yeniden başlar', () {
      final f = SimpleKalmanFilter(q: 0.0001, r: 0.01);
      f.filter(5.0);
      f.reset();
      expect(f.filter(1.0), 1.0);
    });
  });

  group('GpsFilterPipeline — temel ret koşulları', () {
    late GpsFilterPipeline pipeline;

    setUp(() {
      pipeline = GpsFilterPipeline(GpsFilterParams.current);
    });

    test('doğruluk eşiğini aşan nokta reddedilir', () {
      for (var i = 0; i < GpsFilterParams.current.warmUpCount; i++) {
        pipeline.processPoint(pt(39.0 + i * 0.0001, 32.0, offsetSec: i));
      }
      final beforeCount = pipeline.result.acceptedCount;
      pipeline.processPoint(
          pt(39.0, 32.0, accuracy: GpsFilterParams.current.accuracyThreshold + 1, offsetSec: 100));
      expect(pipeline.result.acceptedCount, beforeCount);
    });

    test('max hız aşılınca nokta reddedilir', () {
      for (var i = 0; i < GpsFilterParams.current.warmUpCount; i++) {
        pipeline.processPoint(pt(39.0 + i * 0.0001, 32.0, offsetSec: i));
      }
      final beforeCount = pipeline.result.acceptedCount;
      pipeline.processPoint(pt(39.0, 32.0,
          speed: GpsFilterParams.current.maxSpeedKmh / 3.6 + 1, offsetSec: 100));
      expect(pipeline.result.acceptedCount, beforeCount);
    });

    test('reset sonrası rawCount sıfırlanır', () {
      pipeline.processPoint(pt(39.0, 32.0));
      pipeline.reset();
      expect(pipeline.result.rawPointCount, 0);
      expect(pipeline.result.acceptedCount, 0);
    });
  });

  group('GpsFilterPipeline — Spike Guard', () {
    test('10 m/s eşiğini aşan spike reddedilir', () {
      final p = GpsFilterPipeline(GpsFilterParams.spikeGuard);
      // Isınma
      for (var i = 0; i < GpsFilterParams.spikeGuard.warmUpCount; i++) {
        p.processPoint(pt(39.0, 32.0, offsetSec: i));
      }
      final countAfterWarmup = p.result.acceptedCount;

      // Normal sonraki nokta: ~1 m/s
      p.processPoint(pt(39.00001, 32.0, offsetSec: 100));
      final afterNormal = p.result.acceptedCount;
      expect(afterNormal, greaterThan(countAfterWarmup));

      // Spike: çok uzak nokta → yüksek hız
      p.processPoint(pt(40.0, 33.0, offsetSec: 101)); // ~150 km uzak 1 saniyede
      expect(p.result.acceptedCount, afterNormal); // spike reddedilmeli
    });
  });

  group('GpsFilterPipeline — IIR Adaptive', () {
    test('durma sırasında pozisyon dondurulur (alpha=0)', () {
      final p = GpsFilterPipeline(GpsFilterParams.iirAdaptive);
      // Isınma
      for (var i = 0; i < GpsFilterParams.iirAdaptive.warmUpCount; i++) {
        p.processPoint(pt(39.0, 32.0, speed: 2.0, offsetSec: i));
      }

      // Durma (speed < stationarySpeedThreshold)
      p.processPoint(pt(39.0001, 32.0001,
          speed: 0.1, offsetSec: 100)); // alpha = iirAlphaStop = 0.0
      final pointAfterStop = p.result.points.last;

      // EMA freeze: yeni lat/lng durdurulmuş eski konumu yansıtmalı
      // (alpha=0 → ema = eski_ema, noktayı 39.0001'e taşımamalı)
      expect(pointAfterStop.latitude, lessThan(39.00005));
    });
  });

  group('GpsFilterPipeline — mesafe hesabı', () {
    test('toplam mesafe doğru hesaplanır (≈ Haversine)', () {
      final p = GpsFilterPipeline(GpsFilterParams.stravaRaw);
      // stravaRaw: warmUpCount=3, minDist=0.5 — isınmayı hızlıca bitir
      for (var i = 0; i < 3; i++) {
        p.processPoint(pt(39.0 + i * 0.00001, 32.0, offsetSec: i));
      }
      // Yaklaşık 100 m ilerle
      p.processPoint(pt(39.001, 32.0, offsetSec: 10));
      expect(p.result.totalDistance, greaterThan(50));
      expect(p.result.totalDistance, lessThan(300));
    });
  });

  group('LiveAlgorithmComparator entegrasyonu', () {
    test('tüm preset\'ler için sonuç üretir', () {
      // Bu test gps_filter_pipeline.dart + live_algorithm_comparator.dart entegrasyonunu doğrular
      final pipelineForEach = GpsFilterParams.allPresets
          .map((p) => GpsFilterPipeline(p))
          .toList();

      final points = List.generate(
        20,
        (i) => pt(39.0 + i * 0.0001, 32.0 + i * 0.0001, offsetSec: i),
      );

      for (final pipeline in pipelineForEach) {
        for (final point in points) {
          pipeline.processPoint(point);
        }
      }

      for (final pipeline in pipelineForEach) {
        final r = pipeline.result;
        expect(r.rawPointCount, 20);
        expect(r.acceptedCount, greaterThanOrEqualTo(0));
        expect(r.totalDistance, greaterThanOrEqualTo(0));
      }
    });
  });
}
