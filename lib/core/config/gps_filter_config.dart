/// GPS filtering configuration constants
class GpsFilterConfig {
  // Warm-up phase
  static const int warmUpPointCount = 10;
  static const double warmUpMinDistance = 2.0; // meters
  
  // Post warm-up filtering
  static const double accuracyThreshold = 25.0; // meters
  static const double postWarmUpMinDistance = 5.0; // meters
  static const double stationarySpeedThreshold = 0.5; // m/s
  static const double poorAccuracyThreshold = 15.0; // meters
  
  // Speed validation
  static const double maxSpeedKmh = 50.0; // km/h
  static const double maxImpliedSpeedKmh = 100.0; // km/h
  
  // Pace calculation
  static const double minDistanceForPace = 50.0; // meters
}
