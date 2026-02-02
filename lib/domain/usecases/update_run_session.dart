import '../entities/run_session.dart';
import '../entities/track_point.dart';

class UpdateRunSession {
  UpdateRunSession();

  RunSession execute(RunSession currentSession, TrackPoint newPoint) {
    if (currentSession.status != RunStatus.running) {
      return currentSession;
    }

    if (!newPoint.isAccurate) {
      return currentSession;
    }

    if (!newPoint.isSpeedReasonable()) {
      return currentSession;
    }

    if (newPoint.speed < 0.5 && newPoint.accuracy > 15) {
      return currentSession;
    }

    final updatedPoints = [...currentSession.trackPoints, newPoint];
    
    double additionalDistance = 0;
    if (currentSession.trackPoints.isNotEmpty) {
      final lastPoint = currentSession.trackPoints.last;
      additionalDistance = lastPoint.distanceTo(newPoint);
      
      if (additionalDistance < 5 && newPoint.speed < 0.5) {
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
