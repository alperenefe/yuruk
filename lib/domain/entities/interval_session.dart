import 'package:equatable/equatable.dart';
import 'workout_plan.dart';
import 'interval_step.dart';
import '../../core/config/gps_filter_config.dart';

/// Status of interval session
enum IntervalSessionStatus {
  notStarted,
  inProgress,
  completed,
}

/// Current state of an interval training session
class IntervalSession extends Equatable {
  final WorkoutPlan workoutPlan;
  final int currentStepIndex;
  final double currentStepProgress; // meters or seconds completed in current step
  final IntervalSessionStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  
  // Step offset tracking
  final double stepStartDistance; // Total distance when step started
  final int stepStartTimeSeconds; // Total elapsed seconds when step started
  
  // 👇 YENİ: Current step stats (for tempo calculation)
  final double stepActualDistance; // Actual distance covered in current step
  final int stepActualTimeSeconds; // Actual time spent in current step

  const IntervalSession({
    required this.workoutPlan,
    this.currentStepIndex = 0,
    this.currentStepProgress = 0,
    this.status = IntervalSessionStatus.notStarted,
    this.startTime,
    this.endTime,
    this.stepStartDistance = 0,
    this.stepStartTimeSeconds = 0,
    this.stepActualDistance = 0,
    this.stepActualTimeSeconds = 0,
  });

  /// Get current step
  IntervalStep? get currentStep {
    if (currentStepIndex >= 0 && currentStepIndex < workoutPlan.steps.length) {
      return workoutPlan.steps[currentStepIndex];
    }
    return null;
  }

  /// Get next step
  IntervalStep? get nextStep {
    final nextIndex = currentStepIndex + 1;
    if (nextIndex >= 0 && nextIndex < workoutPlan.steps.length) {
      return workoutPlan.steps[nextIndex];
    }
    return null;
  }

  /// Check if current step is completed
  bool get isCurrentStepCompleted {
    final step = currentStep;
    if (step == null) return false;

    if (step.type == IntervalType.distance) {
      return currentStepProgress >= (step.targetDistance ?? 0);
    } else if (step.type == IntervalType.time) {
      return currentStepProgress >= (step.targetDuration?.inSeconds ?? 0);
    }
    return false;
  }

  /// Check if all steps are completed
  bool get isAllStepsCompleted {
    return currentStepIndex >= workoutPlan.steps.length - 1 && isCurrentStepCompleted;
  }

  /// Get progress percentage for current step (0-100)
  double get currentStepProgressPercentage {
    final step = currentStep;
    if (step == null) return 0;

    if (step.type == IntervalType.distance) {
      final target = step.targetDistance ?? 1;
      return (currentStepProgress / target * 100).clamp(0, 100);
    } else if (step.type == IntervalType.time) {
      final target = (step.targetDuration?.inSeconds ?? 1).toDouble();
      return (currentStepProgress / target * 100).clamp(0, 100);
    }
    return 0;
  }

  /// Calculate actual pace for current/completed step (minutes per km)
  /// Returns null if not enough data
  double? get stepActualPaceMinPerKm {
    if (stepActualDistance < GpsFilterConfig.minDistanceForPace || stepActualTimeSeconds < 1) {
      return null; // Not enough data
    }
    
    final km = stepActualDistance / 1000;
    final minutes = stepActualTimeSeconds / 60;
    return minutes / km;
  }

  /// Get actual pace formatted as MM:SS
  String? get stepActualPaceFormatted {
    final pace = stepActualPaceMinPerKm;
    if (pace == null) return null;
    
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  IntervalSession copyWith({
    WorkoutPlan? workoutPlan,
    int? currentStepIndex,
    double? currentStepProgress,
    IntervalSessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    double? stepStartDistance,
    int? stepStartTimeSeconds,
    double? stepActualDistance,
    int? stepActualTimeSeconds,
  }) {
    return IntervalSession(
      workoutPlan: workoutPlan ?? this.workoutPlan,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentStepProgress: currentStepProgress ?? this.currentStepProgress,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      stepStartDistance: stepStartDistance ?? this.stepStartDistance,
      stepStartTimeSeconds: stepStartTimeSeconds ?? this.stepStartTimeSeconds,
      stepActualDistance: stepActualDistance ?? this.stepActualDistance,
      stepActualTimeSeconds: stepActualTimeSeconds ?? this.stepActualTimeSeconds,
    );
  }

  @override
  List<Object?> get props => [
    workoutPlan,
    currentStepIndex,
    currentStepProgress,
    status,
    startTime,
    endTime,
    stepStartDistance,
    stepStartTimeSeconds,
    stepActualDistance,
    stepActualTimeSeconds,
  ];
}
