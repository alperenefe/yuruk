/// Configuration for interval training feedback and tolerances
class IntervalFeedbackConfig {
  // Mid-step feedback trigger point
  static const double midStepFeedbackPercentage = 50.0; // At 50% progress
  
  // Base tolerance settings
  static const double baseFastTolerance = -5.0; // Base tolerance for being fast (seconds)
  static const double fastToleranceMultiplier = 2.0; // Extra tolerance per min/km faster than 5:00
  static const double slownessTolerance = 0.0; // No tolerance for slowness
  
  /// Get lower tolerance (for being faster) based on target pace
  /// 
  /// Logic: Faster target = more tolerance for being fast
  /// - 3:00 target → -9 sec tolerance (very fast = OK to be faster)
  /// - 4:00 target → -7 sec tolerance
  /// - 5:00 target → -5 sec tolerance
  /// - 6:00 target → -3 sec tolerance (slow = don't go too fast)
  static double getLowerTolerance(double targetPaceMinPerKm) {
    // Calculate how much faster than 5:00 (reference pace)
    const referencePace = 5.0;
    final paceOffset = referencePace - targetPaceMinPerKm;
    
    // Subtract extra tolerance for faster paces (more negative = more tolerant)
    final extraTolerance = paceOffset * fastToleranceMultiplier;
    return baseFastTolerance - extraTolerance;
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
