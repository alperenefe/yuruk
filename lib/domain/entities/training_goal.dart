import 'package:equatable/equatable.dart';

/// Yarış / süre hedefi (ör. 2400 m — 10:20 — 15 Ağustos).
class TrainingGoal extends Equatable {
  final String name;
  final DateTime raceDate;
  final double distanceMeters;
  final String targetTime;
  final String? targetPacePerKm;

  const TrainingGoal({
    required this.name,
    required this.raceDate,
    required this.distanceMeters,
    required this.targetTime,
    this.targetPacePerKm,
  });

  int get daysUntilRace {
    final today = DateTime.now();
    final race = DateTime(raceDate.year, raceDate.month, raceDate.day);
    final now = DateTime(today.year, today.month, today.day);
    return race.difference(now).inDays;
  }

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.toInt()} m';
  }

  @override
  List<Object?> get props =>
      [name, raceDate, distanceMeters, targetTime, targetPacePerKm];
}
