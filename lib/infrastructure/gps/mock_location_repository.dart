import 'dart:async';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/location_repository.dart';

class MockLocationRepository implements LocationRepository {
  StreamController<TrackPoint>? _controller;
  Timer? _timer;
  int _pointIndex = 0;
  
  final List<TrackPoint> _mockRoute = [
    TrackPoint(
      latitude: 41.0082,
      longitude: 28.9784,
      altitude: 100,
      accuracy: 10,
      speed: 3.0,
      bearing: 0,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  Stream<TrackPoint> getLocationStream() {
    _controller ??= StreamController<TrackPoint>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> startTracking() async {
    _pointIndex = 0;
    
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_controller != null && !_controller!.isClosed) {
        final basePoint = _mockRoute[0];
        
        final newPoint = TrackPoint(
          latitude: basePoint.latitude + (_pointIndex * 0.0001),
          longitude: basePoint.longitude + (_pointIndex * 0.0001),
          altitude: basePoint.altitude + (_pointIndex * 0.5),
          accuracy: 8 + (_pointIndex % 3),
          speed: 2.5 + (_pointIndex % 5) * 0.2,
          bearing: (_pointIndex * 10) % 360,
          timestamp: DateTime.now(),
        );
        
        _controller!.add(newPoint);
        _pointIndex++;
      }
    });
  }

  @override
  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    await _controller?.close();
    _controller = null;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    return true;
  }
}
