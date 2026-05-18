import 'package:flutter/material.dart';
import 'dart:math';

class GpsFilterParams {
  final String name;
  final Color color;
  final bool useKalman;
  final double kalmanLatLngQ;
  final double kalmanLatLngR;
  final double accuracyThreshold;
  final double maxSpeedKmh;
  final double maxImpliedSpeedKmh;
  final int warmUpCount;
  final double warmUpMinDistance;
  final double postWarmUpMinDistance;
  final double stationarySpeedThreshold;
  final double poorAccuracyThreshold;

  const GpsFilterParams({
    required this.name,
    required this.color,
    this.useKalman = true,
    this.kalmanLatLngQ = 0.0001,
    this.kalmanLatLngR = 0.01,
    this.accuracyThreshold = 25.0,
    this.maxSpeedKmh = 50.0,
    this.maxImpliedSpeedKmh = 100.0,
    this.warmUpCount = 10,
    this.warmUpMinDistance = 2.0,
    this.postWarmUpMinDistance = 5.0,
    this.stationarySpeedThreshold = 0.5,
    this.poorAccuracyThreshold = 15.0,
  });

  static const GpsFilterParams raw = GpsFilterParams(
    name: 'Ham',
    color: Color(0xFF9E9E9E),
    useKalman: false,
    accuracyThreshold: 9999,
    maxSpeedKmh: 9999,
    maxImpliedSpeedKmh: 9999,
    warmUpCount: 0,
    warmUpMinDistance: 0,
    postWarmUpMinDistance: 0,
    stationarySpeedThreshold: 0,
    poorAccuracyThreshold: 9999,
  );

  static const GpsFilterParams current = GpsFilterParams(
    name: 'Mevcut',
    color: Color(0xFF2196F3),
    useKalman: true,
    kalmanLatLngQ: 0.0001,
    kalmanLatLngR: 0.01,
    accuracyThreshold: 25.0,
    maxSpeedKmh: 50.0,
    maxImpliedSpeedKmh: 100.0,
    warmUpCount: 10,
    warmUpMinDistance: 2.0,
    postWarmUpMinDistance: 5.0,
    stationarySpeedThreshold: 0.5,
    poorAccuracyThreshold: 15.0,
  );

  static const GpsFilterParams aggressiveKalman = GpsFilterParams(
    name: 'Güçlü Kalman',
    color: Color(0xFF4CAF50),
    useKalman: true,
    kalmanLatLngQ: 0.00001,
    kalmanLatLngR: 0.001,
    accuracyThreshold: 25.0,
    maxSpeedKmh: 50.0,
    maxImpliedSpeedKmh: 100.0,
    warmUpCount: 10,
    warmUpMinDistance: 2.0,
    postWarmUpMinDistance: 5.0,
    stationarySpeedThreshold: 0.5,
    poorAccuracyThreshold: 15.0,
  );

  static const GpsFilterParams lenient = GpsFilterParams(
    name: 'Toleranslı',
    color: Color(0xFFFF9800),
    useKalman: true,
    kalmanLatLngQ: 0.0001,
    kalmanLatLngR: 0.01,
    accuracyThreshold: 50.0,
    maxSpeedKmh: 70.0,
    maxImpliedSpeedKmh: 150.0,
    warmUpCount: 5,
    warmUpMinDistance: 1.0,
    postWarmUpMinDistance: 3.0,
    stationarySpeedThreshold: 0.3,
    poorAccuracyThreshold: 25.0,
  );

  static const GpsFilterParams strict = GpsFilterParams(
    name: 'Katı',
    color: Color(0xFFF44336),
    useKalman: true,
    kalmanLatLngQ: 0.0001,
    kalmanLatLngR: 0.01,
    accuracyThreshold: 12.0,
    maxSpeedKmh: 35.0,
    maxImpliedSpeedKmh: 70.0,
    warmUpCount: 15,
    warmUpMinDistance: 3.0,
    postWarmUpMinDistance: 8.0,
    stationarySpeedThreshold: 0.8,
    poorAccuracyThreshold: 10.0,
  );

  static const List<GpsFilterParams> allPresets = [
    raw,
    current,
    aggressiveKalman,
    lenient,
    strict,
  ];

  GpsFilterParams copyWith({
    String? name,
    Color? color,
    bool? useKalman,
    double? kalmanLatLngQ,
    double? kalmanLatLngR,
    double? accuracyThreshold,
    double? maxSpeedKmh,
    double? maxImpliedSpeedKmh,
    int? warmUpCount,
    double? warmUpMinDistance,
    double? postWarmUpMinDistance,
    double? stationarySpeedThreshold,
    double? poorAccuracyThreshold,
  }) {
    return GpsFilterParams(
      name: name ?? this.name,
      color: color ?? this.color,
      useKalman: useKalman ?? this.useKalman,
      kalmanLatLngQ: kalmanLatLngQ ?? this.kalmanLatLngQ,
      kalmanLatLngR: kalmanLatLngR ?? this.kalmanLatLngR,
      accuracyThreshold: accuracyThreshold ?? this.accuracyThreshold,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      maxImpliedSpeedKmh: maxImpliedSpeedKmh ?? this.maxImpliedSpeedKmh,
      warmUpCount: warmUpCount ?? this.warmUpCount,
      warmUpMinDistance: warmUpMinDistance ?? this.warmUpMinDistance,
      postWarmUpMinDistance:
          postWarmUpMinDistance ?? this.postWarmUpMinDistance,
      stationarySpeedThreshold:
          stationarySpeedThreshold ?? this.stationarySpeedThreshold,
      poorAccuracyThreshold:
          poorAccuracyThreshold ?? this.poorAccuracyThreshold,
    );
  }

  static const List<Color> selectableColors = [
    Color(0xFF9E9E9E),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
  ];
}

class SimpleKalmanFilter {
  final double q;
  final double r;
  double _p = 1.0;
  double _x = 0.0;
  double _k = 0.0;
  bool _initialized = false;

  SimpleKalmanFilter({required this.q, required this.r});

  double filter(double measurement, {double? accuracy}) {
    if (!_initialized) {
      _x = measurement;
      _initialized = true;
      return _x;
    }
    double effectiveR = r;
    if (accuracy != null && accuracy > 0) {
      effectiveR = 0.001 + (accuracy / 100.0);
    }
    _p = _p + q;
    _k = _p / (_p + effectiveR);
    _x = _x + _k * (measurement - _x);
    _p = (1 - _k) * _p;
    return _x;
  }

  void reset() {
    _p = 1.0;
    _x = 0.0;
    _k = 0.0;
    _initialized = false;
  }
}

double bearingBetween(
  double lat1, double lon1,
  double lat2, double lon2,
) {
  final dLon = (lon2 - lon1) * (pi / 180);
  final lat1Rad = lat1 * (pi / 180);
  final lat2Rad = lat2 * (pi / 180);
  final y = sin(dLon) * cos(lat2Rad);
  final x = cos(lat1Rad) * sin(lat2Rad) -
      sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
  return atan2(y, x) * (180 / pi);
}

double angleDiff(double a, double b) {
  double diff = (b - a).abs() % 360;
  if (diff > 180) diff = 360 - diff;
  return diff;
}
