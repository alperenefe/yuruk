import 'package:equatable/equatable.dart';
import 'scheduled_day.dart';
import 'training_goal.dart';

class TrainingProgram extends Equatable {
  final String id;
  final TrainingGoal goal;
  final int daysPerWeek;
  final int weeksTotal;
  final List<ScheduledDay> days;
  final DateTime createdAt;
  final bool isActive;
  final String? generatedBy;

  const TrainingProgram({
    required this.id,
    required this.goal,
    required this.daysPerWeek,
    required this.weeksTotal,
    required this.days,
    required this.createdAt,
    this.isActive = true,
    this.generatedBy,
  });

  ScheduledDay? get todayDay {
    for (final d in days) {
      if (d.isToday) return d;
    }
    return null;
  }

  /// Bugün için planlı koşu varsa onu, yoksa gelecek 7 gün içindeki
  /// en yakın bekleyen koşu gününü döner. Haftaya atanmış antrenmanı
  /// bugün yapmak isteyenler için.
  ScheduledDay? get nextPendingDay {
    final today = todayDay;
    if (today != null) return today;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final upcoming = days
        .where((d) =>
            d.status == ScheduledDayStatus.pending &&
            !d.isRest &&
            d.date.isAfter(todayDate) &&
            d.date.difference(todayDate).inDays <= 7)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  int get completedCount =>
      days.where((d) => d.status == ScheduledDayStatus.completed).length;

  int get runnableDaysCount => days.where((d) => !d.isRest).length;

  List<ScheduledDay> daysForWeekContaining(DateTime anchor) {
    final start = anchor.subtract(Duration(days: anchor.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return days
        .where((d) =>
            !d.date.isBefore(DateTime(start.year, start.month, start.day)) &&
            !d.date.isAfter(DateTime(end.year, end.month, end.day)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  List<Object?> get props =>
      [id, goal, daysPerWeek, weeksTotal, days, createdAt, isActive, generatedBy];
}
