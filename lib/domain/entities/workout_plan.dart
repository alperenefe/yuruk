import 'package:equatable/equatable.dart';
import 'interval_step.dart';

/// A complete workout plan containing multiple interval steps
class WorkoutPlan extends Equatable {
  final String id;
  final String name;
  final List<IntervalStep> steps;
  final DateTime createdAt;
  final String? description;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.steps,
    required this.createdAt,
    this.description,
  });

  /// Calculate total distance (only for distance-based steps)
  double get totalDistance {
    return steps
        .where((step) => step.type == IntervalType.distance)
        .fold(0.0, (sum, step) => sum + (step.targetDistance ?? 0));
  }

  /// Calculate total duration (only for time-based steps)
  Duration get totalDuration {
    return steps
        .where((step) => step.type == IntervalType.time)
        .fold(Duration.zero, (sum, step) => sum + (step.targetDuration ?? Duration.zero));
  }

  /// Get number of steps
  int get stepCount => steps.length;

  /// Check if plan is valid
  bool get isValid => steps.isNotEmpty && name.isNotEmpty;

  WorkoutPlan copyWith({
    String? id,
    String? name,
    List<IntervalStep>? steps,
    DateTime? createdAt,
    String? description,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [id, name, steps, createdAt, description];
}
