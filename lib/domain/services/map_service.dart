import '../entities/track_point.dart';

abstract class MapService {
  void centerOnPosition(double latitude, double longitude);
  
  void addRoutePoint(TrackPoint point);
  
  void clearRoute();
  
  void enableAutoCenter();
  
  void disableAutoCenter();
  
  bool get isAutoCenterEnabled;
}
