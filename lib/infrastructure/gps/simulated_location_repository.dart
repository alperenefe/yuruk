import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/entities/track_point.dart';

/// Simulated GPS location repository for emulator testing
/// Simulates a realistic 5km running route with speed variations and GPS jitter
class SimulatedLocationRepository implements LocationRepository {
  StreamController<TrackPoint>? _trackPointController;
  Timer? _simulationTimer;
  int _currentPointIndex = 0;
  final Random _random = Random();
  
  // Realistic route: Maçka Park, Istanbul (5km loop)
  final List<_RoutePoint> _route = [
    // Start: Maçka Parkı entrance
    _RoutePoint(41.0445, 28.9948, targetPaceMinPerKm: 5.0), // Easy start
    _RoutePoint(41.0452, 28.9955, targetPaceMinPerKm: 5.0),
    _RoutePoint(41.0460, 28.9960, targetPaceMinPerKm: 4.8), // Picking up speed
    _RoutePoint(41.0468, 28.9965, targetPaceMinPerKm: 4.5),
    _RoutePoint(41.0475, 28.9970, targetPaceMinPerKm: 4.5), // Steady fast
    _RoutePoint(41.0482, 28.9972, targetPaceMinPerKm: 4.3),
    _RoutePoint(41.0488, 28.9975, targetPaceMinPerKm: 4.3),
    _RoutePoint(41.0495, 28.9977, targetPaceMinPerKm: 4.5),
    _RoutePoint(41.0500, 28.9980, targetPaceMinPerKm: 4.8), // Slight uphill
    _RoutePoint(41.0505, 28.9985, targetPaceMinPerKm: 5.0),
    _RoutePoint(41.0508, 28.9990, targetPaceMinPerKm: 5.2), // Uphill
    _RoutePoint(41.0510, 28.9995, targetPaceMinPerKm: 5.5),
    _RoutePoint(41.0512, 29.0000, targetPaceMinPerKm: 5.5),
    _RoutePoint(41.0513, 29.0005, targetPaceMinPerKm: 5.3), // Peak
    _RoutePoint(41.0512, 29.0010, targetPaceMinPerKm: 4.8), // Downhill - fast!
    _RoutePoint(41.0510, 29.0015, targetPaceMinPerKm: 4.3),
    _RoutePoint(41.0507, 29.0018, targetPaceMinPerKm: 4.0), // Fastest section
    _RoutePoint(41.0503, 29.0020, targetPaceMinPerKm: 4.0),
    _RoutePoint(41.0498, 29.0022, targetPaceMinPerKm: 4.2),
    _RoutePoint(41.0493, 29.0023, targetPaceMinPerKm: 4.5),
    _RoutePoint(41.0488, 29.0024, targetPaceMinPerKm: 4.7),
    _RoutePoint(41.0483, 29.0023, targetPaceMinPerKm: 5.0), // Leveling off
    _RoutePoint(41.0478, 29.0020, targetPaceMinPerKm: 5.0),
    _RoutePoint(41.0473, 29.0017, targetPaceMinPerKm: 5.2),
    _RoutePoint(41.0468, 29.0013, targetPaceMinPerKm: 5.5), // Getting tired
    _RoutePoint(41.0463, 29.0010, targetPaceMinPerKm: 5.5),
    _RoutePoint(41.0458, 29.0007, targetPaceMinPerKm: 5.3),
    _RoutePoint(41.0453, 29.0003, targetPaceMinPerKm: 5.0),
    _RoutePoint(41.0450, 28.9998, targetPaceMinPerKm: 4.8), // Final push
    _RoutePoint(41.0448, 28.9993, targetPaceMinPerKm: 4.5),
    _RoutePoint(41.0446, 28.9988, targetPaceMinPerKm: 4.3),
    _RoutePoint(41.0445, 28.9983, targetPaceMinPerKm: 4.5),
    _RoutePoint(41.0445, 28.9978, targetPaceMinPerKm: 4.7),
    _RoutePoint(41.0445, 28.9973, targetPaceMinPerKm: 5.0),
    _RoutePoint(41.0445, 28.9968, targetPaceMinPerKm: 5.5), // Cooldown
    _RoutePoint(41.0445, 28.9963, targetPaceMinPerKm: 6.0),
    _RoutePoint(41.0445, 28.9958, targetPaceMinPerKm: 6.5),
    _RoutePoint(41.0445, 28.9953, targetPaceMinPerKm: 7.0), // Walking finish
    _RoutePoint(41.0445, 28.9948, targetPaceMinPerKm: 0.0), // Stopped
  ];

  @override
  Future<void> startTracking() async {
    // No-op for simulation (tracking starts with getLocationStream)
  }

  @override
  Future<void> stopTracking() async {
    _simulationTimer?.cancel();
    _trackPointController?.close();
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return true; // Always enabled in simulation
  }

  @override
  Future<bool> requestPermission() async {
    return true; // Always granted in simulation
  }

  @override
  Future<TrackPoint> getCurrentPosition() async {
    final firstPoint = _route.first;
    return TrackPoint(
      latitude: firstPoint.lat,
      longitude: firstPoint.lng,
      altitude: 50.0 + _random.nextDouble() * 5,
      accuracy: 8.0 + _random.nextDouble() * 4,
      speed: 0.0,
      bearing: 0.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<TrackPoint> getLocationStream() {
    _trackPointController = StreamController<TrackPoint>.broadcast();
    _currentPointIndex = 0;

    // Simulate GPS updates every 2-3 seconds (realistic for running)
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPointIndex >= _route.length) {
        // Loop back to start or stop
        _currentPointIndex = 0;
        timer.cancel();
        return;
      }

      final routePoint = _route[_currentPointIndex];
      final trackPoint = _generateTrackPoint(routePoint);
      
      if (_trackPointController != null && !_trackPointController!.isClosed) {
        _trackPointController!.add(trackPoint);
      }

      _currentPointIndex++;
    });

    return _trackPointController!.stream;
  }

  TrackPoint _generateTrackPoint(_RoutePoint routePoint) {
    // Add GPS jitter (realistic GPS inaccuracy)
    const jitterAmount = 0.00003; // ~3 meters
    final latJitter = (_random.nextDouble() - 0.5) * jitterAmount;
    final lngJitter = (_random.nextDouble() - 0.5) * jitterAmount;

    // Calculate speed from target pace (min/km → m/s)
    double speed;
    if (routePoint.targetPaceMinPerKm > 0) {
      // Convert pace to speed: pace (min/km) → speed (m/s)
      // Example: 5 min/km = 5 * 60 = 300 seconds per km = 1000m / 300s = 3.33 m/s
      speed = 1000.0 / (routePoint.targetPaceMinPerKm * 60.0);
      // Add some variation (±10%)
      speed *= (0.9 + _random.nextDouble() * 0.2);
    } else {
      speed = 0.0; // Stopped
    }

    // Simulate GPS accuracy variation (better accuracy at higher speed)
    final accuracy = speed > 1.0 
        ? 8.0 + _random.nextDouble() * 8.0  // 8-16m when moving
        : 15.0 + _random.nextDouble() * 10.0; // 15-25m when slow/stopped

    // Altitude with some variation (simulate hills)
    final altitude = 50.0 + _random.nextDouble() * 30.0;

    // Bearing (direction) - roughly follows route
    final bearing = _currentPointIndex > 0
        ? _calculateBearing(
            _route[_currentPointIndex - 1].lat,
            _route[_currentPointIndex - 1].lng,
            routePoint.lat,
            routePoint.lng,
          )
        : 0.0;

    return TrackPoint(
      latitude: routePoint.lat + latJitter,
      longitude: routePoint.lng + lngJitter,
      altitude: altitude,
      accuracy: accuracy,
      speed: speed,
      bearing: bearing,
      timestamp: DateTime.now(),
    );
  }

  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * pi / 180.0;
    final lat1Rad = lat1 * pi / 180.0;
    final lat2Rad = lat2 * pi / 180.0;

    final y = sin(dLng) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) - 
              sin(lat1Rad) * cos(lat2Rad) * cos(dLng);

    final bearing = atan2(y, x) * 180.0 / pi;
    return (bearing + 360.0) % 360.0;
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _trackPointController?.close();
  }
}

class _RoutePoint {
  final double lat;
  final double lng;
  final double targetPaceMinPerKm;

  _RoutePoint(this.lat, this.lng, {required this.targetPaceMinPerKm});
}
