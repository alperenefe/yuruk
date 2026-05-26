import '../entities/location_access_status.dart';
import '../entities/track_point.dart';

abstract class LocationRepository {
  Stream<TrackPoint> getLocationStream();
  
  Future<void> startTracking();
  
  Future<void> stopTracking();
  
  Future<bool> isLocationServiceEnabled();
  
  Future<bool> requestPermission();

  Future<LocationAccessStatus> getAccessStatus();

  Future<bool> openAppSettings();

  Future<TrackPoint> getCurrentPosition();
  
  Future<TrackPoint?> getLastKnownPosition();
}
