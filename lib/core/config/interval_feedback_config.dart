/// Configuration for interval training feedback and tolerances
class IntervalFeedbackConfig {
  // Mid-step feedback trigger point
  static const double midStepFeedbackPercentage = 50.0; // At 50% progress
  
  // Pace tolerance thresholds (in minutes per km)
  static const double fastPaceThreshold = 5.0; // Below this = fast pace
  
  // Dynamic tolerance for being FASTER than target (negative values)
  static const double fastPaceFastTolerance = -10.0; // For fast paces (<5:00)
  static const double normalPaceFastTolerance = -5.0; // For normal paces (≥5:00)
  
  // Tolerance for being SLOWER than target (positive values)
  static const double slownessTolerance = 0.0; // 0 = no tolerance, warn immediately
  
  /// Get lower tolerance (for being faster) based on target pace
  static double getLowerTolerance(double targetPaceMinPerKm) {
    return targetPaceMinPerKm < fastPaceThreshold
        ? fastPaceFastTolerance
        : normalPaceFastTolerance;
  }
  
  /// Get upper tolerance (for being slower) - currently fixed at 0
  static double getUpperTolerance(double targetPaceMinPerKm) {
    return slownessTolerance;
  }
  
  /// Check if pace difference is within acceptable range
  static bool isWithinTolerance(
    double actualPaceMinPerKm,
    double targetPaceMinPerKm,
  ) {
    final diffSeconds = (actualPaceMinPerKm - targetPaceMinPerKm) * 60;
    final lowerTolerance = getLowerTolerance(targetPaceMinPerKm);
    final upperTolerance = getUpperTolerance(targetPaceMinPerKm);
    
    return diffSeconds >= lowerTolerance && diffSeconds <= upperTolerance;
  }
}
