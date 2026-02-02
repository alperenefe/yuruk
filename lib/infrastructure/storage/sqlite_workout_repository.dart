import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/entities/interval_step.dart';
import '../../domain/repositories/workout_repository.dart';
import '../database/database_helper.dart';

class SqliteWorkoutRepository implements WorkoutRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  @override
  Future<void> savePlan(WorkoutPlan plan) async {
    final db = await _databaseHelper.database;
    
    final stepsJson = plan.steps
        .map((step) => {
              'id': step.id,
              'type': step.type.name,
              'targetDistance': step.targetDistance,
              'targetDuration': step.targetDuration?.inSeconds,
              'targetPace': step.targetPace,
              'isRest': step.isRest,
              'name': step.name,
            })
        .toList();

    await db.insert(
      'workout_plans',
      {
        'id': plan.id,
        'name': plan.name,
        'description': plan.description,
        'steps': jsonEncode(stepsJson),
        'createdAt': plan.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<WorkoutPlan?> getPlanById(String id) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      'workout_plans',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return _mapToWorkoutPlan(maps.first);
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      'workout_plans',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _mapToWorkoutPlan(map)).toList();
  }

  @override
  Future<void> deletePlan(String id) async {
    final db = await _databaseHelper.database;
    
    await db.delete(
      'workout_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updatePlan(WorkoutPlan plan) async {
    await savePlan(plan); // Same as save with replace conflict algorithm
  }

  WorkoutPlan _mapToWorkoutPlan(Map<String, dynamic> map) {
    final stepsJson = jsonDecode(map['steps'] as String) as List;
    final steps = stepsJson
        .map((stepMap) {
          final type = stepMap['type'] == 'distance' 
              ? IntervalType.distance 
              : IntervalType.time;
          
          return IntervalStep(
            id: stepMap['id'] as String,
            type: type,
            targetDistance: stepMap['targetDistance'] as double?,
            targetDuration: stepMap['targetDuration'] != null
                ? Duration(seconds: stepMap['targetDuration'] as int)
                : null,
            targetPace: stepMap['targetPace'] as String?,
            isRest: stepMap['isRest'] as bool? ?? false,
            name: stepMap['name'] as String?,
          );
        })
        .toList();

    return WorkoutPlan(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      steps: steps,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}
