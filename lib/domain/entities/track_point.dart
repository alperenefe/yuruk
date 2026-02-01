import 'dart:math';
import 'package:equatable/equatable.dart';

class TrackPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;
  final double? bearing;
  final DateTime timestamp;

  const TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
    this.bearing,
    required this.timestamp,
  });

  bool get isAccurate {
    return accuracy <= 25.0;
  }

  bool isSpeedReasonable({double maxSpeedKmh = 50.0}) {
    final speedKmh = speed * 3.6;
    return speedKmh <= maxSpeedKmh;
  }

  double distanceTo(TrackPoint other) {
    const double earthRadius = 6371000;
    
    final lat1Rad = latitude * (pi / 180);
    final lat2Rad = other.latitude * (pi / 180);
    final deltaLat = (other.latitude - latitude) * (pi / 180);
    final deltaLon = (other.longitude - longitude) * (pi / 180);

    final a = pow(sin(deltaLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        pow(sin(deltaLon / 2), 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    altitude,
    accuracy,
    speed,
    bearing,
    timestamp,
  ];
}
