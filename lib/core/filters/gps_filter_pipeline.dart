import '../../domain/entities/track_point.dart';
import '../config/gps_filter_params.dart';
import '../utils/geo_math.dart';
import 'simple_kalman_filter.dart';

/// Tek bir filtre konfigürasyonu için çalıştırma sonucu.
class FilteredTrackResult {
  final GpsFilterParams params;
  final List<TrackPoint> points;
  final int rawPointCount;
  final int rejectedCount;
  final double totalDistance;

  const FilteredTrackResult({
    required this.params,
    required this.points,
    required this.rawPointCount,
    required this.rejectedCount,
    required this.totalDistance,
  });

  int get acceptedCount => rawPointCount - rejectedCount;

  double get retentionRate =>
      rawPointCount == 0 ? 0 : acceptedCount / rawPointCount;

  double get smoothnessScore {
    if (points.length < 3) return 0;
    double total = 0;
    for (int i = 1; i < points.length - 1; i++) {
      final b1 = bearingBetween(
        points[i - 1].latitude, points[i - 1].longitude,
        points[i].latitude, points[i].longitude,
      );
      final b2 = bearingBetween(
        points[i].latitude, points[i].longitude,
        points[i + 1].latitude, points[i + 1].longitude,
      );
      total += angleDiff(b1, b2);
    }
    return total;
  }

  String get distanceFormatted {
    if (totalDistance >= 1000) {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
    return '${totalDistance.toStringAsFixed(0)} m';
  }
}

/// GPS noktalarını belirli bir [GpsFilterParams] ile filtreleyen pipeline.
/// Her koşu veya Lab analizi için ayrı bir instance oluşturulur.
class GpsFilterPipeline {
  final GpsFilterParams params;

  final SimpleKalmanFilter _latFilter;
  final SimpleKalmanFilter _lngFilter;

  final List<TrackPoint> _filteredPoints = [];
  int _rawCount = 0;
  int _rejectedCount = 0;
  double _totalDistance = 0;

  // Spike Guard: son kabul edilen ham GPS noktası (Kalman öncesi).
  TrackPoint? _lastRawForSpike;

  // IIR Adaptive: GPS Doppler hızı bazlı state machine.
  double _emaLat = 0;
  double _emaLon = 0;
  bool _emaInitialized = false;
  double _prevGpsSpeedMs = 0;

  GpsFilterPipeline(this.params)
      : _latFilter =
            SimpleKalmanFilter(q: params.kalmanLatLngQ, r: params.kalmanLatLngR),
        _lngFilter =
            SimpleKalmanFilter(q: params.kalmanLatLngQ, r: params.kalmanLatLngR);

  // ─── Public API ───────────────────────────────────────────────────────────

  void processPoint(TrackPoint raw) {
    _rawCount++;
    final isWarmingUp = _filteredPoints.length < params.warmUpCount;

    if (!isWarmingUp && _shouldReject(raw)) return;

    _lastRawForSpike = raw;

    final (lat, lng) = _applySmoother(raw);

    final filtered = TrackPoint(
      latitude: lat,
      longitude: lng,
      altitude: raw.altitude,
      accuracy: raw.accuracy,
      speed: raw.speed,
      bearing: raw.bearing,
      timestamp: raw.timestamp,
    );

    if (_shouldRejectByDistance(filtered, raw, isWarmingUp)) return;

    _totalDistance += _filteredPoints.isEmpty ? 0 : _filteredPoints.last.distanceTo(filtered);
    _filteredPoints.add(filtered);
  }

  FilteredTrackResult get result => FilteredTrackResult(
        params: params,
        points: List.unmodifiable(_filteredPoints),
        rawPointCount: _rawCount,
        rejectedCount: _rejectedCount,
        totalDistance: _totalDistance,
      );

  void reset() {
    _filteredPoints.clear();
    _rawCount = 0;
    _rejectedCount = 0;
    _totalDistance = 0;
    _latFilter.reset();
    _lngFilter.reset();
    _lastRawForSpike = null;
    _emaLat = 0;
    _emaLon = 0;
    _emaInitialized = false;
    _prevGpsSpeedMs = 0;
  }

  // ─── Filtre aşamaları ─────────────────────────────────────────────────────

  /// Doğruluk, hız, Spike Guard temel reddini uygular. true = reddet.
  bool _shouldReject(TrackPoint raw) {
    if (_rejectByAccuracy(raw)) return true;
    if (_rejectBySpeed(raw)) return true;
    if (_rejectByStationaryAndPoorAccuracy(raw)) return true;
    if (_rejectBySpikeGuard(raw)) return true;
    return false;
  }

  bool _rejectByAccuracy(TrackPoint raw) {
    if (raw.accuracy > params.accuracyThreshold) {
      _rejectedCount++;
      return true;
    }
    return false;
  }

  bool _rejectBySpeed(TrackPoint raw) {
    if (raw.speed * 3.6 > params.maxSpeedKmh) {
      _rejectedCount++;
      return true;
    }
    return false;
  }

  bool _rejectByStationaryAndPoorAccuracy(TrackPoint raw) {
    if (raw.speed < params.stationarySpeedThreshold &&
        raw.accuracy > params.poorAccuracyThreshold) {
      _rejectedCount++;
      return true;
    }
    return false;
  }

  /// Spike Guard: ham GPS koordinat hızı fiziksel sınırı geçiyorsa reddet.
  /// Spike reddedilince _lastRawForSpike güncellenmez → zincir kırılır.
  bool _rejectBySpikeGuard(TrackPoint raw) {
    if (params.rawSpikeSpeedMs <= 0 || _lastRawForSpike == null) return false;
    final timeDiffMs =
        raw.timestamp.difference(_lastRawForSpike!.timestamp).inMilliseconds;
    if (timeDiffMs <= 0) return false;
    final rawSpeedMs =
        _lastRawForSpike!.distanceTo(raw) / (timeDiffMs / 1000.0);
    if (rawSpeedMs > params.rawSpikeSpeedMs) {
      _rejectedCount++;
      return true;
    }
    return false;
  }

  /// IIR veya Kalman uygulayarak düzleştirilmiş (lat, lng) döndürür.
  (double lat, double lng) _applySmoother(TrackPoint raw) {
    if (params.useAdaptiveIir) return _applyIirAdaptive(raw);
    if (params.useKalman) return _applyKalman(raw);
    return (raw.latitude, raw.longitude);
  }

  /// IIR Adaptive: GPS Doppler hızına göre 3 durum state machine.
  (double, double) _applyIirAdaptive(TrackPoint raw) {
    final double alpha;
    if (raw.speed < params.stationarySpeedThreshold) {
      alpha = params.iirAlphaStop;
    } else {
      final speedChange = (raw.speed - _prevGpsSpeedMs).abs();
      alpha = speedChange > params.speedChangeThresholdMs
          ? params.iirAlphaPaceChange
          : params.iirAlphaSteady;
    }
    _prevGpsSpeedMs = raw.speed;

    if (!_emaInitialized) {
      _emaLat = raw.latitude;
      _emaLon = raw.longitude;
      _emaInitialized = true;
    } else {
      _emaLat = alpha * raw.latitude + (1 - alpha) * _emaLat;
      _emaLon = alpha * raw.longitude + (1 - alpha) * _emaLon;
    }
    return (_emaLat, _emaLon);
  }

  (double, double) _applyKalman(TrackPoint raw) {
    return (
      _latFilter.filter(raw.latitude, accuracy: raw.accuracy),
      _lngFilter.filter(raw.longitude, accuracy: raw.accuracy),
    );
  }

  /// Mesafe kapısı: çok yakın/durağan noktaları ve implied speed aşımını reddeder.
  bool _shouldRejectByDistance(
      TrackPoint filtered, TrackPoint raw, bool isWarmingUp) {
    if (_filteredPoints.isEmpty) return false;

    final last = _filteredPoints.last;
    final dist = last.distanceTo(filtered);
    final minDist =
        isWarmingUp ? params.warmUpMinDistance : params.postWarmUpMinDistance;

    if (dist < minDist && raw.speed < params.stationarySpeedThreshold) {
      _rejectedCount++;
      return true;
    }

    if (_filteredPoints.length >= 2) {
      final timeDiff =
          filtered.timestamp.difference(last.timestamp).inSeconds;
      if (timeDiff > 0 && (dist / timeDiff) * 3.6 > params.maxImpliedSpeedKmh) {
        _rejectedCount++;
        return true;
      }
    }
    return false;
  }
}
