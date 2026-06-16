import 'package:equatable/equatable.dart';

enum ScheduledDayType {
  easy,
  interval,
  tempo,
  longRun,
  rest,
  race,
  test,
  unknown,
}

enum ScheduledDayStatus { pending, completed, skipped }

ScheduledDayType scheduledDayTypeFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'easy':
      return ScheduledDayType.easy;
    case 'interval':
      return ScheduledDayType.interval;
    case 'tempo':
      return ScheduledDayType.tempo;
    case 'long':
    case 'long_run':
      return ScheduledDayType.longRun;
    case 'rest':
      return ScheduledDayType.rest;
    case 'race':
      return ScheduledDayType.race;
    case 'test':
      return ScheduledDayType.test;
    default:
      return ScheduledDayType.unknown;
  }
}

String scheduledDayTypeToString(ScheduledDayType type) {
  switch (type) {
    case ScheduledDayType.easy:
      return 'easy';
    case ScheduledDayType.interval:
      return 'interval';
    case ScheduledDayType.tempo:
      return 'tempo';
    case ScheduledDayType.longRun:
      return 'long';
    case ScheduledDayType.rest:
      return 'rest';
    case ScheduledDayType.race:
      return 'race';
    case ScheduledDayType.test:
      return 'test';
    case ScheduledDayType.unknown:
      return 'unknown';
  }
}

ScheduledDayStatus scheduledDayStatusFromString(String? raw) {
  switch (raw) {
    case 'completed':
      return ScheduledDayStatus.completed;
    case 'skipped':
      return ScheduledDayStatus.skipped;
    default:
      return ScheduledDayStatus.pending;
  }
}

/// Planlanmış tek antrenman günü.
class ScheduledDay extends Equatable {
  final String id;
  final String programId;
  final DateTime date;
  final ScheduledDayType type;
  final String title;
  final String? description;
  final double? targetDistanceMeters;
  final String? targetPacePerKm;
  final String? workoutPlanId;
  final ScheduledDayStatus status;

  const ScheduledDay({
    required this.id,
    required this.programId,
    required this.date,
    required this.type,
    required this.title,
    this.description,
    this.targetDistanceMeters,
    this.targetPacePerKm,
    this.workoutPlanId,
    this.status = ScheduledDayStatus.pending,
  });

  bool get isToday {
    final n = DateTime.now();
    return date.year == n.year && date.month == n.month && date.day == n.day;
  }

  bool get isRest => type == ScheduledDayType.rest;

  bool get isRunnable =>
      !isRest && type != ScheduledDayType.unknown && status == ScheduledDayStatus.pending;

  ScheduledDay copyWith({
    ScheduledDayStatus? status,
    String? workoutPlanId,
  }) {
    return ScheduledDay(
      id: id,
      programId: programId,
      date: date,
      type: type,
      title: title,
      description: description,
      targetDistanceMeters: targetDistanceMeters,
      targetPacePerKm: targetPacePerKm,
      workoutPlanId: workoutPlanId ?? this.workoutPlanId,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        programId,
        date,
        type,
        title,
        description,
        targetDistanceMeters,
        targetPacePerKm,
        workoutPlanId,
        status,
      ];
}
