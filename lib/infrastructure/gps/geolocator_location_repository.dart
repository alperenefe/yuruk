import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_access_status.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/location_repository.dart';

class GeolocatorLocationRepository implements LocationRepository {
  StreamSubscription<Position>? _positionSubscription;
  StreamController<TrackPoint>? _trackPointController;

  static LocationSettings get _locationSettings {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

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

          if (kDebugMode) {
            print('📍 GPS raw: (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}) '
                  'acc=${position.accuracy.toStringAsFixed(1)}m spd=${position.speed.toStringAsFixed(1)}m/s');
          }

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
    final status = await getAccessStatus();
    if (status == LocationAccessStatus.granted) return true;
    if (status == LocationAccessStatus.deniedForever) return false;

    if (status == LocationAccessStatus.denied) {
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    }

    return false;
  }

  @override
  Future<LocationAccessStatus> getAccessStatus() async {
    if (!await isLocationServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }
    final permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccessStatus.granted;
      case LocationPermission.deniedForever:
        return LocationAccessStatus.deniedForever;
      case LocationPermission.denied:
        return LocationAccessStatus.denied;
      case LocationPermission.unableToDetermine:
        return LocationAccessStatus.denied;
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

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

  @override
  Future<TrackPoint?> getLastKnownPosition() async {
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;
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
