import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/entities/interval_step.dart';
import '../../domain/entities/scheduled_day.dart';
import '../../domain/entities/training_goal.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/entities/workout_plan.dart';

class TrainingPlanParseException implements Exception {
  final String message;
  TrainingPlanParseException(this.message);

  @override
  String toString() => message;
}

class TrainingPlanImportResult {
  final TrainingProgram program;
  final List<WorkoutPlan> workoutPlans;

  const TrainingPlanImportResult({
    required this.program,
    required this.workoutPlans,
  });
}

/// ChatGPT / Gemini JSON → [TrainingProgram] + gün başına [WorkoutPlan].
class TrainingPlanJsonParser {
  static const _uuid = Uuid();

  TrainingPlanImportResult parse(String rawJson) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson.trim());
    } catch (e) {
      throw TrainingPlanParseException('Geçersiz JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw TrainingPlanParseException('Kök öğe bir JSON nesnesi olmalı.');
    }

    final version = decoded['version'];
    if (version != 1 && version != '1') {
      throw TrainingPlanParseException('version: 1 gerekli (bulunan: $version).');
    }

    final goalMap = decoded['goal'];
    if (goalMap is! Map<String, dynamic>) {
      throw TrainingPlanParseException('goal alanı eksik.');
    }

    final metaMap = decoded['meta'] as Map<String, dynamic>? ?? {};
    final weeks = decoded['weeks'];
    if (weeks is! List || weeks.isEmpty) {
      throw TrainingPlanParseException('weeks dizisi boş veya eksik.');
    }

    final programId = _uuid.v4();
    final goal = _parseGoal(goalMap);
    final workoutPlans = <WorkoutPlan>[];
    final days = <ScheduledDay>[];

    for (final weekRaw in weeks) {
      if (weekRaw is! Map<String, dynamic>) continue;
      final weekDays = weekRaw['days'];
      if (weekDays is! List) continue;

      for (final dayRaw in weekDays) {
        if (dayRaw is! Map<String, dynamic>) continue;
        final day = _parseDay(
          dayRaw,
          programId: programId,
          workoutPlans: workoutPlans,
        );
        days.add(day);
      }
    }

    if (days.isEmpty) {
      throw TrainingPlanParseException('Hiç antrenman günü bulunamadı.');
    }

    days.sort((a, b) => a.date.compareTo(b.date));

    final program = TrainingProgram(
      id: programId,
      goal: goal,
      daysPerWeek: (metaMap['daysPerWeek'] as num?)?.toInt() ?? 4,
      weeksTotal: (metaMap['weeksTotal'] as num?)?.toInt() ?? weeks.length,
      days: days,
      createdAt: DateTime.now(),
      isActive: true,
      generatedBy: metaMap['generatedBy'] as String?,
    );

    return TrainingPlanImportResult(program: program, workoutPlans: workoutPlans);
  }

  TrainingGoal _parseGoal(Map<String, dynamic> m) {
    final name = m['name'] as String? ?? 'Hedef';
    final raceDateStr = m['raceDate'] as String?;
    if (raceDateStr == null) {
      throw TrainingPlanParseException('goal.raceDate (YYYY-MM-DD) gerekli.');
    }
    final raceDate = DateTime.tryParse(raceDateStr);
    if (raceDate == null) {
      throw TrainingPlanParseException('goal.raceDate geçersiz: $raceDateStr');
    }

    final distance = (m['distanceMeters'] as num?)?.toDouble();
    if (distance == null || distance <= 0) {
      throw TrainingPlanParseException('goal.distanceMeters pozitif olmalı.');
    }

    final targetTime = m['targetTime'] as String?;
    if (targetTime == null || targetTime.isEmpty) {
      throw TrainingPlanParseException('goal.targetTime gerekli (ör. 10:20).');
    }

    return TrainingGoal(
      name: name,
      raceDate: raceDate,
      distanceMeters: distance,
      targetTime: targetTime,
      targetPacePerKm: m['targetPacePerKm'] as String?,
    );
  }

  ScheduledDay _parseDay(
    Map<String, dynamic> m, {
    required String programId,
    required List<WorkoutPlan> workoutPlans,
  }) {
    final dateStr = m['date'] as String?;
    if (dateStr == null) {
      throw TrainingPlanParseException('Her günde date (YYYY-MM-DD) gerekli.');
    }
    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      throw TrainingPlanParseException('Geçersiz tarih: $dateStr');
    }

    final type = scheduledDayTypeFromString(m['type'] as String?);
    final title = m['title'] as String? ?? 'Antrenman';
    String? workoutPlanId;

    final workout = m['workout'];
    if (workout is Map<String, dynamic>) {
      final stepsRaw = workout['steps'];
      if (stepsRaw is List && stepsRaw.isNotEmpty) {
        final steps = _parseSteps(stepsRaw);
        final plan = WorkoutPlan(
          id: _uuid.v4(),
          name: workout['name'] as String? ?? title,
          steps: steps,
          createdAt: DateTime.now(),
          description: m['description'] as String?,
        );
        workoutPlans.add(plan);
        workoutPlanId = plan.id;
      }
    }

    // LLM workout yazmadıysa gün tipine göre otomatik plan üret.
    if (workoutPlanId == null && type != ScheduledDayType.rest) {
      final dist = (m['targetDistanceMeters'] as num?)?.toDouble();
      final pace = m['targetPacePerKm'] as String?;
      final autoPlan = _autoPlan(
        type: type,
        title: title,
        description: m['description'] as String?,
        distanceMeters: dist,
        targetPace: pace,
      );
      if (autoPlan != null) {
        workoutPlans.add(autoPlan);
        workoutPlanId = autoPlan.id;
      }
    }

    return ScheduledDay(
      id: _uuid.v4(),
      programId: programId,
      date: DateTime(date.year, date.month, date.day),
      type: type,
      title: title,
      description: m['description'] as String?,
      targetDistanceMeters: (m['targetDistanceMeters'] as num?)?.toDouble(),
      targetPacePerKm: m['targetPacePerKm'] as String?,
      workoutPlanId: workoutPlanId,
    );
  }

  List<IntervalStep> _parseSteps(List<dynamic> raw) {
    final steps = <IntervalStep>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final typeStr = item['type'] as String? ?? 'distance';
      final isRest = item['isRest'] as bool? ?? false;
      final name = item['name'] as String?;
      final targetPace = item['targetPace'] as String?;

      if (typeStr == 'time') {
        final sec = (item['durationSeconds'] as num?)?.toInt() ??
            (item['duration'] as num?)?.toInt();
        if (sec == null) continue;
        steps.add(IntervalStep.time(
          id: _uuid.v4(),
          duration: Duration(seconds: sec),
          targetPace: targetPace,
          isRest: isRest,
          name: name,
        ));
      } else {
        final meters = (item['meters'] as num?)?.toDouble() ??
            (item['targetDistance'] as num?)?.toDouble();
        if (meters == null) continue;
        steps.add(IntervalStep.distance(
          id: _uuid.v4(),
          meters: meters,
          targetPace: targetPace,
          isRest: isRest,
          name: name,
        ));
      }
    }
    if (steps.isEmpty) {
      throw TrainingPlanParseException('workout.steps boş veya geçersiz.');
    }
    return steps;
  }

  /// Gün tipine göre otomatik koşu planı üret.
  ///
  /// | Tip     | Plan yapısı                                        |
  /// |---------|----------------------------------------------------|
  /// | easy    | 1 adım — mesafe @ kolay pace                       |
  /// | tempo   | Isınma 1.5km + tempo bloğu + soğuma 1km            |
  /// | longRun | 1 adım — uzun mesafe, pace opsiyonel               |
  /// | test    | 1 adım — hedef mesafe, pace yok (max efor)         |
  /// | race    | 1 adım — yarış mesafesi @ hedef pace               |
  /// | interval| Sadece mesafe varsa 1 adım, workout yoksa fallback |
  /// | unknown | null — plan üretilmez                              |
  WorkoutPlan? _autoPlan({
    required ScheduledDayType type,
    required String title,
    String? description,
    double? distanceMeters,
    String? targetPace,
  }) {
    final now = DateTime.now();

    switch (type) {
      case ScheduledDayType.easy:
        final dist = distanceMeters ?? 5000;
        return WorkoutPlan(
          id: _uuid.v4(),
          name: title,
          description: description,
          createdAt: now,
          steps: [
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: dist,
              targetPace: targetPace,
              name: 'Kolay koşu',
            ),
          ],
        );

      case ScheduledDayType.tempo:
        final mainDist = distanceMeters ?? 5000;
        // Toplam mesafenin %20'si ısınma/soğuma, geri kalanı tempo.
        final warmup = (mainDist * 0.2).clamp(1000.0, 2000.0);
        final cooldown = (mainDist * 0.15).clamp(800.0, 1500.0);
        final tempoDist = (mainDist - warmup - cooldown).clamp(500.0, double.infinity);
        return WorkoutPlan(
          id: _uuid.v4(),
          name: title,
          description: description,
          createdAt: now,
          steps: [
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: warmup,
              name: 'Isınma',
              // Isınma pace'i hedeften ~1 dk/km yavaş
              targetPace: _slowerPace(targetPace, 60),
            ),
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: tempoDist,
              targetPace: targetPace,
              name: 'Tempo',
            ),
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: cooldown,
              name: 'Soğuma',
              targetPace: _slowerPace(targetPace, 90),
            ),
          ],
        );

      case ScheduledDayType.longRun:
        final dist = distanceMeters ?? 10000;
        return WorkoutPlan(
          id: _uuid.v4(),
          name: title,
          description: description,
          createdAt: now,
          steps: [
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: dist,
              targetPace: targetPace,
              name: 'Uzun koşu',
            ),
          ],
        );

      case ScheduledDayType.test:
        final dist = distanceMeters ?? 1600;
        return WorkoutPlan(
          id: _uuid.v4(),
          name: title,
          description: description ?? 'Zaman denemesi — maksimum efor',
          createdAt: now,
          steps: [
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: 1000,
              name: 'Isınma',
              targetPace: _slowerPace(targetPace, 90),
            ),
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: dist,
              // Test günü pace hedefi yok — kullanıcı max koşar
              name: 'Test — max efor',
            ),
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: 500,
              name: 'Soğuma',
              targetPace: _slowerPace(targetPace, 120),
            ),
          ],
        );

      case ScheduledDayType.race:
        if (distanceMeters == null) return null;
        return WorkoutPlan(
          id: _uuid.v4(),
          name: title,
          description: description,
          createdAt: now,
          steps: [
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: distanceMeters,
              targetPace: targetPace,
              name: 'Yarış',
            ),
          ],
        );

      case ScheduledDayType.interval:
        // LLM workout.steps yazmadı ama mesafe belirtilmiş → tek adım fallback
        if (distanceMeters == null) return null;
        return WorkoutPlan(
          id: _uuid.v4(),
          name: title,
          description: description,
          createdAt: now,
          steps: [
            IntervalStep.distance(
              id: _uuid.v4(),
              meters: distanceMeters,
              targetPace: targetPace,
              name: 'Interval',
            ),
          ],
        );

      case ScheduledDayType.rest:
      case ScheduledDayType.unknown:
        return null;
    }
  }

  /// Bir pace'e [extraSeconds] sn ekler (daha yavaş).
  /// Örn. "4:30" + 60 sn → "5:30"
  String? _slowerPace(String? pace, int extraSeconds) {
    if (pace == null) return null;
    final parts = pace.split(':');
    if (parts.length != 2) return pace;
    final min = int.tryParse(parts[0]);
    final sec = int.tryParse(parts[1]);
    if (min == null || sec == null) return pace;
    final totalSec = min * 60 + sec + extraSeconds;
    final newMin = totalSec ~/ 60;
    final newSec = totalSec % 60;
    return '$newMin:${newSec.toString().padLeft(2, '0')}';
  }
}
