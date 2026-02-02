/// Configuration for interval training feedback and tolerances
class IntervalFeedbackConfig {
  // Mid-step feedback trigger point
  static const double midStepFeedbackPercentage = 50.0; // At 50% progress
  
  /// Get lower tolerance (for being faster) based on target pace
  /// 
  /// Logic: Tempo = Tolerans (hızlı koşarken hızlanmak zor)
  /// - 3:00 target → -3 sec (çok hızlı = az tolerans)
  /// - 4:00 target → -4 sec
  /// - 5:00 target → -5 sec
  /// - 6:00 target → -6 sec (yavaş = daha az tolerans)
  static double getLowerTolerance(double targetPaceMinPerKm) {
    return -targetPaceMinPerKm;
  }
  
  /// Get upper tolerance (for being slower) - fixed at +5 seconds
  static double getUpperTolerance(double targetPaceMinPerKm) {
    return 5.0; // +5 sec tolerance for slowness
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
