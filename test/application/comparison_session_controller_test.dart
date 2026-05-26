import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/application/controllers/comparison_session_controller.dart';
import 'package:yuruk/core/config/gps_filter_params.dart';
import 'package:yuruk/domain/entities/run_session.dart';
import 'package:yuruk/domain/entities/track_point.dart';

TrackPoint _pt(double lat, double lng, int sec) => TrackPoint(
      latitude: lat,
      longitude: lng,
      altitude: 0,
      accuracy: 8,
      speed: 1.5,
      timestamp: DateTime(2024, 1, 1, 10).add(Duration(seconds: sec)),
    );

RunSession _sessionWithPoints(List<TrackPoint> points) => RunSession(
      id: 's1',
      startTime: DateTime(2024),
      status: RunStatus.stopped,
      trackPoints: points,
      rawTrackPoints: points,
      totalDistance: 200,
      elapsedTime: const Duration(minutes: 2),
    );

RunSession _emptySession() => RunSession(
      id: 's2',
      startTime: DateTime(2024),
      status: RunStatus.stopped,
      trackPoints: const [],
      totalDistance: 0,
      elapsedTime: Duration.zero,
    );

void main() {
  group('ComparisonSessionController', () {
    late ComparisonSessionController controller;

    setUp(() {
      controller = ComparisonSessionController();
    });

    test('başlangıçta tüm presetler yüklü, isLoaded=false', () {
      expect(controller.state.configs, GpsFilterParams.allPresets);
      expect(controller.state.isLoaded, false);
      expect(controller.state.results, isEmpty);
    });

    test('loadRunSession: noktalı oturum → isLoaded=true, tüm configler için sonuç', () {
      final points = List.generate(
        25,
        (i) => _pt(39.0 + i * 0.0001, 32.0, i),
      );
      final session = _sessionWithPoints(points);
      controller.loadRunSession(session);

      expect(controller.state.isLoaded, true);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.results.length, controller.state.configs.length);
      expect(controller.state.rawPoints, points);
    });

    test('loadRunSession: boş oturum → isLoaded=false, hata mesajı var, eski harita korunmaz', () {
      // Önce gerçek bir koşu yükle
      final points = List.generate(20, (i) => _pt(39.0 + i * 0.0001, 32.0, i));
      controller.loadRunSession(_sessionWithPoints(points));
      expect(controller.state.isLoaded, true);

      // Sonra boş oturum yüklemeyi dene
      controller.loadRunSession(_emptySession());
      expect(controller.state.isLoaded, false);
      expect(controller.state.errorMessage, isNotNull);
      expect(controller.state.results, isEmpty); // eski sonuçlar temizlenmeli
      expect(controller.state.rawPoints, isEmpty);
    });

    test('addConfig → sonuç sayısı artar', () {
      final points = List.generate(20, (i) => _pt(39.0 + i * 0.0001, 32.0, i));
      controller.loadRunSession(_sessionWithPoints(points));
      final before = controller.state.results.length;

      controller.addConfig(GpsFilterParams.current.copyWith(name: 'Test'));
      expect(controller.state.results.length, before + 1);
    });

    test('removeConfig → sonuç sayısı azalır', () {
      final points = List.generate(20, (i) => _pt(39.0 + i * 0.0001, 32.0, i));
      controller.loadRunSession(_sessionWithPoints(points));
      final before = controller.state.configs.length;

      controller.removeConfig(0);
      expect(controller.state.configs.length, before - 1);
      expect(controller.state.results.length, before - 1);
    });

    test('updateConfig → aynı sayıda sonuç, güncellenen config yansır', () {
      final points = List.generate(20, (i) => _pt(39.0 + i * 0.0001, 32.0, i));
      controller.loadRunSession(_sessionWithPoints(points));
      final before = controller.state.results.length;

      const newConfig = GpsFilterParams.raw;
      controller.updateConfig(0, newConfig);
      expect(controller.state.results.length, before);
      expect(controller.state.configs[0].name, newConfig.name);
    });

    test('reset → isLoaded=false, configs korunur, results temizlenir', () {
      final points = List.generate(20, (i) => _pt(39.0 + i * 0.0001, 32.0, i));
      controller.loadRunSession(_sessionWithPoints(points));
      final configsBefore = controller.state.configs;

      controller.reset();
      expect(controller.state.isLoaded, false);
      expect(controller.state.results, isEmpty);
      expect(controller.state.configs, configsBefore); // config listesi korunur
    });

    test('her config için sonuç ayrı rota içerir (harita çizimi)', () {
      final points = List.generate(
        30,
        (i) => _pt(39.0 + i * 0.0001, 32.0 + i * 0.0001, i),
      );
      controller.loadRunSession(_sessionWithPoints(points));

      // Her config'in bağımsız bir sonucu olmalı
      final results = controller.state.results;
      expect(results.length, controller.state.configs.length);

      // En az bir config'de nokta olmalı (Ham filter hepsini geçirir)
      final rawResult =
          results.firstWhere((r) => r.params.name == GpsFilterParams.raw.name);
      expect(rawResult.points, isNotEmpty);
    });

    test('removeConfig hiddenIndices indekslerini kaydırır', () {
      final points = List.generate(10, (i) => _pt(39.0 + i * 0.0001, 32.0, i));
      controller.loadRunSession(_sessionWithPoints(points));
      final count = controller.state.configs.length;
      controller.soloVisibility(3);
      expect(controller.state.hiddenIndices.length, count - 1);
      expect(controller.state.isVisible(3), true);

      controller.removeConfig(0);
      expect(controller.state.configs.length, count - 1);
      expect(controller.state.isVisible(2), true);
      expect(controller.state.hiddenIndices.length, count - 2);
    });
  });
}
