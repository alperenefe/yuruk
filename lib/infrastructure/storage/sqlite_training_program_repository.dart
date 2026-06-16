import 'package:sqflite/sqflite.dart';

import '../../domain/entities/scheduled_day.dart';
import '../../domain/entities/training_goal.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/repositories/training_program_repository.dart';
import '../database/database_helper.dart';

class SqliteTrainingProgramRepository implements TrainingProgramRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<void> saveProgram(TrainingProgram program) async {
    final database = await _db.database;
    await database.transaction((txn) async {
      await txn.update('training_programs', {'isActive': 0});
      await txn.insert(
        'training_programs',
        {
          'id': program.id,
          'name': program.goal.name,
          'raceDate': program.goal.raceDate.millisecondsSinceEpoch,
          'distanceMeters': program.goal.distanceMeters,
          'targetTime': program.goal.targetTime,
          'targetPacePerKm': program.goal.targetPacePerKm,
          'daysPerWeek': program.daysPerWeek,
          'weeksTotal': program.weeksTotal,
          'generatedBy': program.generatedBy,
          'createdAt': program.createdAt.millisecondsSinceEpoch,
          'isActive': program.isActive ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'scheduled_days',
        where: 'programId = ?',
        whereArgs: [program.id],
      );

      for (final day in program.days) {
        await txn.insert('scheduled_days', _dayToMap(day));
      }
    });
  }

  @override
  Future<TrainingProgram?> getActiveProgram() async {
    final database = await _db.database;
    final rows = await database.query(
      'training_programs',
      where: 'isActive = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _mapProgram(rows.first, database);
  }

  @override
  Future<TrainingProgram?> getProgramById(String id) async {
    final database = await _db.database;
    final rows = await database.query(
      'training_programs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _mapProgram(rows.first, database);
  }

  @override
  Future<void> setActiveProgram(String programId) async {
    final database = await _db.database;
    await database.transaction((txn) async {
      await txn.update('training_programs', {'isActive': 0});
      await txn.update(
        'training_programs',
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [programId],
      );
    });
  }

  @override
  Future<void> deactivateAll() async {
    final database = await _db.database;
    await database.update('training_programs', {'isActive': 0});
  }

  @override
  Future<void> updateDayStatus(String dayId, ScheduledDayStatus status) async {
    final database = await _db.database;
    await database.update(
      'scheduled_days',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [dayId],
    );
  }

  @override
  Future<void> deleteProgram(String id) async {
    final database = await _db.database;
    await database.transaction((txn) async {
      await txn.delete('scheduled_days', where: 'programId = ?', whereArgs: [id]);
      await txn.delete('training_programs', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<TrainingProgram?> getActiveProgramReferencingWorkoutPlan(
    String workoutPlanId,
  ) async {
    final active = await getActiveProgram();
    if (active == null) return null;
    final linked = active.days.any((d) => d.workoutPlanId == workoutPlanId);
    return linked ? active : null;
  }

  @override
  Future<void> clearWorkoutPlanReferences(String workoutPlanId) async {
    final database = await _db.database;
    await database.update(
      'scheduled_days',
      {'workoutPlanId': null},
      where: 'workoutPlanId = ?',
      whereArgs: [workoutPlanId],
    );
  }

  Future<TrainingProgram> _mapProgram(
    Map<String, dynamic> row,
    Database database,
  ) async {
    final dayRows = await database.query(
      'scheduled_days',
      where: 'programId = ?',
      whereArgs: [row['id']],
      orderBy: 'date ASC',
    );

    final days = dayRows.map(_mapDay).toList();
    final goal = TrainingGoal(
      name: row['name'] as String,
      raceDate: DateTime.fromMillisecondsSinceEpoch(row['raceDate'] as int),
      distanceMeters: (row['distanceMeters'] as num).toDouble(),
      targetTime: row['targetTime'] as String,
      targetPacePerKm: row['targetPacePerKm'] as String?,
    );

    return TrainingProgram(
      id: row['id'] as String,
      goal: goal,
      daysPerWeek: row['daysPerWeek'] as int,
      weeksTotal: row['weeksTotal'] as int,
      days: days,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
      isActive: (row['isActive'] as int) == 1,
      generatedBy: row['generatedBy'] as String?,
    );
  }

  ScheduledDay _mapDay(Map<String, dynamic> row) {
    return ScheduledDay(
      id: row['id'] as String,
      programId: row['programId'] as String,
      date: DateTime.parse(row['date'] as String),
      type: scheduledDayTypeFromString(row['type'] as String?),
      title: row['title'] as String,
      description: row['description'] as String?,
      targetDistanceMeters: (row['targetDistanceMeters'] as num?)?.toDouble(),
      targetPacePerKm: row['targetPacePerKm'] as String?,
      workoutPlanId: row['workoutPlanId'] as String?,
      status: scheduledDayStatusFromString(row['status'] as String?),
    );
  }

  Map<String, Object?> _dayToMap(ScheduledDay day) {
    return {
      'id': day.id,
      'programId': day.programId,
      'date':
          '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}',
      'type': scheduledDayTypeToString(day.type),
      'title': day.title,
      'description': day.description,
      'targetDistanceMeters': day.targetDistanceMeters,
      'targetPacePerKm': day.targetPacePerKm,
      'workoutPlanId': day.workoutPlanId,
      'status': day.status.name,
    };
  }
}
