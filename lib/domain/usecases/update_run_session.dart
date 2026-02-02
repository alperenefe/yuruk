import 'package:flutter/foundation.dart';
import '../entities/run_session.dart';
import '../entities/track_point.dart';
import '../../core/config/gps_filter_config.dart';

class UpdateRunSession {
  UpdateRunSession();

  RunSession execute(RunSession currentSession, TrackPoint newPoint) {
    if (currentSession.status != RunStatus.running) {
      if (kDebugMode) print('❌ Session not running');
      return currentSession;
    }

    // Warm-up phase: First N points get more tolerant filtering
    final isWarmingUp = currentSession.trackPoints.length < GpsFilterConfig.warmUpPointCount;

    if (!isWarmingUp && !newPoint.isAccurate) {
      if (kDebugMode) {
        print('❌ Poor accuracy: ${newPoint.accuracy.toStringAsFixed(1)}m');
      }
      return currentSession;
    }

    if (!newPoint.isSpeedReasonable()) {
      if (kDebugMode) {
        print('❌ Speed: ${(newPoint.speed * 3.6).toStringAsFixed(1)} km/h');
      }
      return currentSession;
    }

    // Skip stationary check during warm-up
    if (!isWarmingUp && 
        newPoint.speed < GpsFilterConfig.stationarySpeedThreshold && 
        newPoint.accuracy > GpsFilterConfig.poorAccuracyThreshold) {
      if (kDebugMode) print('❌ Stationary + poor acc');
      return currentSession;
    }

    final updatedPoints = [...currentSession.trackPoints, newPoint];
    
    double additionalDistance = 0;
    if (currentSession.trackPoints.isNotEmpty) {
      final lastPoint = currentSession.trackPoints.last;
      additionalDistance = lastPoint.distanceTo(newPoint);
      
      // Lower distance threshold during warm-up
      final minDistance = isWarmingUp 
          ? GpsFilterConfig.warmUpMinDistance 
          : GpsFilterConfig.postWarmUpMinDistance;
      if (additionalDistance < minDistance && 
          newPoint.speed < GpsFilterConfig.stationarySpeedThreshold) {
        if (kDebugMode) {
          print('❌ Distance: ${additionalDistance.toStringAsFixed(1)}m');
        }
        return currentSession;
      }
      
      final timeDiffSeconds = newPoint.timestamp.difference(lastPoint.timestamp).inSeconds;
      if (timeDiffSeconds > 0) {
        final impliedSpeed = additionalDistance / timeDiffSeconds;
        final impliedSpeedKmh = impliedSpeed * 3.6;
        
        if (impliedSpeedKmh > GpsFilterConfig.maxImpliedSpeedKmh) {
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
