import '../entities/run_session.dart';
import '../entities/track_point.dart';

class UpdateRunSession {
  UpdateRunSession();

  RunSession execute(RunSession currentSession, TrackPoint newPoint) {
    if (currentSession.status != RunStatus.running) {
      print('❌ Session not running');
      return currentSession;
    }

    // İlk 10 nokta için daha toleranslı filtre (GPS warm-up)
    final isWarmingUp = currentSession.trackPoints.length < 10;

    if (!isWarmingUp && !newPoint.isAccurate) {
      print('❌ Poor accuracy: ${newPoint.accuracy.toStringAsFixed(1)}m');
      return currentSession;
    }

    if (!newPoint.isSpeedReasonable()) {
      print('❌ Speed: ${(newPoint.speed * 3.6).toStringAsFixed(1)} km/h');
      return currentSession;
    }

    // Warm-up sırasında bu filtreyi atla
    if (!isWarmingUp && newPoint.speed < 0.5 && newPoint.accuracy > 15) {
      print('❌ Stationary + poor acc');
      return currentSession;
    }

    final updatedPoints = [...currentSession.trackPoints, newPoint];
    
    double additionalDistance = 0;
    if (currentSession.trackPoints.isNotEmpty) {
      final lastPoint = currentSession.trackPoints.last;
      additionalDistance = lastPoint.distanceTo(newPoint);
      
      // Warm-up sırasında distance filter'ı 2m'ye düşür
      final minDistance = isWarmingUp ? 2.0 : 5.0;
      if (additionalDistance < minDistance && newPoint.speed < 0.5) {
        print('❌ Distance: ${additionalDistance.toStringAsFixed(1)}m');
        return currentSession;
      }
      
      final timeDiffSeconds = newPoint.timestamp.difference(lastPoint.timestamp).inSeconds;
      if (timeDiffSeconds > 0) {
        final impliedSpeed = additionalDistance / timeDiffSeconds;
        final impliedSpeedKmh = impliedSpeed * 3.6;
        
        if (impliedSpeedKmh > 100) {
          return currentSession;
        }
      }
    }

    final newTotalDistance = currentSession.totalDistance + additionalDistance;
    final elapsedTime = newPoint.timestamp.difference(currentSession.startTime);

    return currentSession.copyWith(
      trackPoints: updatedPoints,
      totalDistance: newTotalDistance,
      elapsedTime: elapsedTime,
    );
  }
}
