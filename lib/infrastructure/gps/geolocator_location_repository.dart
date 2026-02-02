import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/location_repository.dart';

class GeolocatorLocationRepository implements LocationRepository {
  StreamSubscription<Position>? _positionSubscription;
  StreamController<TrackPoint>? _trackPointController;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
  );

  @override
  Stream<TrackPoint> getLocationStream() {
    _trackPointController ??= StreamController<TrackPoint>.broadcast();
    return _trackPointController!.stream;
  }

  @override
  Future<void> startTracking() async {
    await _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      (Position position) {
        if (_trackPointController != null && !_trackPointController!.isClosed) {
          final trackPoint = TrackPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            altitude: position.altitude,
            accuracy: position.accuracy,
            speed: position.speed,
            bearing: position.heading,
            timestamp: position.timestamp,
          );
          
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
