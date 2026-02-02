import 'package:equatable/equatable.dart';

/// Type of interval step
enum IntervalType {
  distance, // Distance-based (e.g., 400m)
  time,     // Time-based (e.g., 2 minutes)
}

/// Single step in a workout plan
class IntervalStep extends Equatable {
  final String id;
  final IntervalType type;
  final double? targetDistance; // in meters (for distance-based)
  final Duration? targetDuration; // for time-based
  final String? targetPace; // e.g., "5:10" (MM:SS per km) - optional
  final bool isRest; // Is this a rest interval?
  final String? name; // Optional name (e.g., "Warm-up", "Fast", "Recovery")

  const IntervalStep({
    required this.id,
    required this.type,
    this.targetDistance,
    this.targetDuration,
    this.targetPace,
    this.isRest = false,
    this.name,
  });

  /// Create a distance-based interval
  factory IntervalStep.distance({
    required String id,
    required double meters,
    String? targetPace,
    bool isRest = false,
    String? name,
  }) {
    return IntervalStep(
      id: id,
      type: IntervalType.distance,
      targetDistance: meters,
      targetPace: targetPace,
      isRest: isRest,
      name: name,
    );
  }

  /// Create a time-based interval
  factory IntervalStep.time({
    required String id,
    required Duration duration,
    String? targetPace,
    bool isRest = false,
    String? name,
  }) {
    return IntervalStep(
      id: id,
      type: IntervalType.time,
      targetDuration: duration,
      targetPace: targetPace,
      isRest: isRest,
      name: name,
    );
  }

  /// Format step for display
  String get displayText {
    final sb = StringBuffer();
    
    if (name != null) {
      sb.write('$name: ');
    }
    
    if (type == IntervalType.distance && targetDistance != null) {
      if (targetDistance! >= 1000) {
        sb.write('${(targetDistance! / 1000).toStringAsFixed(1)} km');
      } else {
        sb.write('${targetDistance!.toInt()} m');
      }
    } else if (type == IntervalType.time && targetDuration != null) {
      final minutes = targetDuration!.inMinutes;
      final seconds = targetDuration!.inSeconds.remainder(60);
      if (minutes > 0) {
        sb.write('$minutes dk');
        if (seconds > 0) sb.write(' $seconds sn');
      } else {
        sb.write('$seconds sn');
      }
    }
    
    if (targetPace != null && !isRest) {
      sb.write(' @ $targetPace/km');
    }
    
    if (isRest) {
      sb.write(' (dinlenme)');
    }
    
    return sb.toString();
  }

  @override
  List<Object?> get props => [
    id,
    type,
    targetDistance,
    targetDuration,
    targetPace,
    isRest,
    name,
  ];
}
