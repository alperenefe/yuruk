import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../../core/filters/kalman_filter.dart';

class GeolocatorLocationRepository implements LocationRepository {
  StreamSubscription<Position>? _positionSubscription;
  StreamController<TrackPoint>? _trackPointController;
  final GpsKalmanFilter _kalmanFilter = GpsKalmanFilter();

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0, // Her GPS güncellemesini al (1-2 saniyede bir)
  );

  @override
  Stream<TrackPoint> getLocationStream() {
    _trackPointController ??= StreamController<TrackPoint>.broadcast();
    return _trackPointController!.stream;
  }

  @override
  Future<void> startTracking() async {
    await _positionSubscription?.cancel();
    _kalmanFilter.reset(); // Reset Kalman filter for new tracking session

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      (Position position) {
        if (_trackPointController != null && !_trackPointController!.isClosed) {
          // Apply Kalman filter to GPS data
          final filtered = _kalmanFilter.filter(
            latitude: position.latitude,
            longitude: position.longitude,
            altitude: position.altitude,
            speed: position.speed,
            accuracy: position.accuracy,
          );
          
          final trackPoint = TrackPoint(
            latitude: filtered[0],  // Filtered latitude
            longitude: filtered[1], // Filtered longitude
            altitude: filtered[2],  // Filtered altitude
            accuracy: position.accuracy,
            speed: filtered[3],     // Filtered speed
            bearing: position.heading,
            timestamp: position.timestamp,
          );
          
          print('📍 GPS: raw=(${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}) '
                'filtered=(${filtered[0].toStringAsFixed(6)}, ${filtered[1].toStringAsFixed(6)}) '
                'acc=${position.accuracy.toStringAsFixed(1)}m');
          
          _trackPointController!.add(trackPoint);
        }
      },
      onError: (error) {
        if (_trackPointController != null && !_trackPointController!.isClosed) {
          _trackPointController!.addError(error);
        }
      },
    );
  }

  @override
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _trackPointController?.close();
    _trackPointController = null;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  @override
  Future<TrackPoint> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _locationSettings,
    );
    
    return TrackPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      bearing: position.heading,
      timestamp: position.timestamp,
    );
  }
}
