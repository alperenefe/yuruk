import '../entities/track_point.dart';

abstract class LocationRepository {
  Stream<TrackPoint> getLocationStream();
  
  Future<void> startTracking();
  
  Future<void> stopTracking();
  
  Future<bool> isLocationServiceEnabled();
  
  Future<bool> requestPermission();
}
