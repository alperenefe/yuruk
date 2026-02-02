import '../entities/run_session.dart';
import '../entities/interval_step.dart';
import '../entities/interval_session.dart';

/// Service for generating voice announcements during runs and intervals
class AnnouncementService {
  /// Get start announcement
  String getStartAnnouncement() {
    return 'Koşu başladı';
  }

  /// Get stop announcement with run summary
  String getStopAnnouncement(RunSession session) {
    final km = (session.totalDistance / 1000).toStringAsFixed(2);
    final minutes = session.elapsedTime.inMinutes;
    final seconds = session.elapsedTime.inSeconds.remainder(60);
    final pace = session.averagePaceFormatted;
    
    if (session.totalDistance < 100) {
      return 'Koşu durduruldu';
    }
    
    return 'Koşu tamamlandı. $km kilometre. Süre $minutes dakika $seconds saniye. Ortalama tempo $pace';
  }

  /// Interval step started announcement
  String getIntervalStepStartAnnouncement(IntervalStep step) {
    if (step.isRest) {
      return 'Dinlenme başladı';
    }

    final sb = StringBuffer();
    
    if (step.type == IntervalType.distance && step.targetDistance != null) {
      final distance = step.targetDistance!;
      if (distance >= 1000) {
        sb.write('${(distance / 1000).toStringAsFixed(1)} kilometre');
      } else {
        sb.write('${distance.toInt()} metre');
      }
    } else if (step.type == IntervalType.time && step.targetDuration != null) {
      final minutes = step.targetDuration!.inMinutes;
      final seconds = step.targetDuration!.inSeconds.remainder(60);
      if (minutes > 0) {
        sb.write('$minutes dakika');
        if (seconds > 0) sb.write(' $seconds saniye');
      } else {
        sb.write('$seconds saniye');
      }
    }

    if (step.name != null && step.name!.isNotEmpty) {
      sb.write(' ${step.name!.toLowerCase()}');
    }
    
    sb.write(' başladı');
    return sb.toString();
  }

  /// Interval step completed announcement with tempo feedback
  String getIntervalStepCompletedAnnouncement(
    IntervalStep step,
    IntervalSession session,
  ) {
    if (step.isRest) {
      return 'Dinlenme tamamlandı';
    }

    final sb = StringBuffer();
    
    // Step completed
    if (step.type == IntervalType.distance && step.targetDistance != null) {
      final distance = step.targetDistance!;
      if (distance >= 1000) {
        sb.write('${(distance / 1000).toStringAsFixed(1)} kilometre tamamlandı');
      } else {
        sb.write('${distance.toInt()} metre tamamlandı');
      }
    } else if (step.type == IntervalType.time && step.targetDuration != null) {
      sb.write('Tamamlandı');
    }

    // Tempo feedback (only if target pace is set)
    if (step.targetPace != null && session.stepActualPaceFormatted != null) {
      final actualPace = session.stepActualPaceMinPerKm!;
      final targetPace = _parsePace(step.targetPace!);
      
      if (targetPace != null) {
        sb.write('. Tempo ${session.stepActualPaceFormatted}, hedef ${step.targetPace}');
        
        final diff = (actualPace - targetPace) * 60; // seconds difference
        if (diff.abs() < 3) {
          sb.write('. Mükemmel');
        } else if (diff < 0) {
          // Faster than target
          sb.write('. ${diff.abs().toInt()} saniye hızlısın');
        } else {
          // Slower than target
          sb.write('. ${diff.toInt()} saniye yavaşsın');
        }
      }
    }

    return sb.toString();
  }

  /// Workout completed announcement
  String getWorkoutCompletedAnnouncement() {
    return 'Tüm intervallar tamamlandı. Harika iş!';
  }

  /// Parse pace string (MM:SS) to double (minutes per km)
  double? _parsePace(String pace) {
    final parts = pace.split(':');
    if (parts.length != 2) return null;
    
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    
    if (minutes == null || seconds == null) return null;
    
    return minutes + (seconds / 60);
  }
}
