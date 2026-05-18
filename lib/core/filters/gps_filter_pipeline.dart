import '../../domain/entities/track_point.dart';
import '../config/gps_filter_params.dart';

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

class GpsFilterPipeline {
  final GpsFilterParams params;

  final SimpleKalmanFilter _latFilter;
  final SimpleKalmanFilter _lngFilter;

  final List<TrackPoint> _filteredPoints = [];
  int _rawCount = 0;
  int _rejectedCount = 0;
  double _totalDistance = 0;

  GpsFilterPipeline(this.params)
      : _latFilter = SimpleKalmanFilter(q: params.kalmanLatLngQ, r: params.kalmanLatLngR),
        _lngFilter = SimpleKalmanFilter(q: params.kalmanLatLngQ, r: params.kalmanLatLngR);

  void processPoint(TrackPoint raw) {
    _rawCount++;

    final isWarmingUp = _filteredPoints.length < params.warmUpCount;

    if (!isWarmingUp) {
      if (raw.accuracy > params.accuracyThreshold) {
        _rejectedCount++;
        return;
      }

      final speedKmh = raw.speed * 3.6;
      if (speedKmh > params.maxSpeedKmh) {
        _rejectedCount++;
        return;
      }

      if (raw.speed < params.stationarySpeedThreshold &&
          raw.accuracy > params.poorAccuracyThreshold) {
        _rejectedCount++;
        return;
      }
    }

    double lat = raw.latitude;
    double lng = raw.longitude;

    if (params.useKalman) {
      lat = _latFilter.filter(raw.latitude, accuracy: raw.accuracy);
      lng = _lngFilter.filter(raw.longitude, accuracy: raw.accuracy);
    }

    final filteredPoint = TrackPoint(
      latitude: lat,
      longitude: lng,
      altitude: raw.altitude,
      accuracy: raw.accuracy,
      speed: raw.speed,
      bearing: raw.bearing,
      timestamp: raw.timestamp,
    );

    if (_filteredPoints.isNotEmpty) {
      final last = _filteredPoints.last;
      final dist = last.distanceTo(filteredPoint);
      final minDist = isWarmingUp
          ? params.warmUpMinDistance
          : params.postWarmUpMinDistance;

      if (dist < minDist && raw.speed < params.stationarySpeedThreshold) {
        _rejectedCount++;
        return;
      }

      if (_filteredPoints.length >= 2) {
        final timeDiff =
            filteredPoint.timestamp.difference(last.timestamp).inSeconds;
        if (timeDiff > 0) {
          final impliedSpeedKmh = (dist / timeDiff) * 3.6;
          if (impliedSpeedKmh > params.maxImpliedSpeedKmh) {
            _rejectedCount++;
            return;
          }
        }
      }

      _totalDistance += dist;
    }

    _filteredPoints.add(filteredPoint);
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
  }
}
