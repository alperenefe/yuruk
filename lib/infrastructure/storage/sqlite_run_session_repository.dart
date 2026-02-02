import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../database/database_helper.dart';

class SqliteRunSessionRepository implements RunSessionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  @override
  Future<void> saveSession(RunSession session) async {
    final db = await _databaseHelper.database;
    
    final trackPointsJson = session.trackPoints
        .map((tp) => {
              'latitude': tp.latitude,
              'longitude': tp.longitude,
              'altitude': tp.altitude,
              'accuracy': tp.accuracy,
              'speed': tp.speed,
              'bearing': tp.bearing,
              'timestamp': tp.timestamp.millisecondsSinceEpoch,
            })
        .toList();

    await db.insert(
      'run_sessions',
      {
        'id': session.id,
        'startTime': session.startTime.millisecondsSinceEpoch,
        'endTime': session.endTime?.millisecondsSinceEpoch,
        'status': session.status.name,
        'trackPoints': jsonEncode(trackPointsJson),
        'totalDistance': session.totalDistance,
        'elapsedTime': session.elapsedTime.inMilliseconds,
        'averageBpm': session.averageBpm,
        'notes': session.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<RunSession?> getSessionById(String id) async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      'run_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return _mapToRunSession(maps.first);
  }

  @override
  Future<List<RunSession>> getAllSessions() async {
    final db = await _databaseHelper.database;
    
    final maps = await db.query(
      'run_sessions',
      orderBy: 'startTime DESC',
    );

    return maps.map((map) => _mapToRunSession(map)).toList();
  }

  @override
  Future<void> deleteSession(String id) async {
    final db = await _databaseHelper.database;
    
    await db.delete(
      'run_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  RunSession _mapToRunSession(Map<String, dynamic> map) {
    final trackPointsJson = jsonDecode(map['trackPoints'] as String) as List;
    final trackPoints = trackPointsJson
        .map((tp) => TrackPoint(
              latitude: tp['latitude'] as double,
              longitude: tp['longitude'] as double,
              altitude: tp['altitude'] as double,
              accuracy: tp['accuracy'] as double,
              speed: tp['speed'] as double,
              bearing: tp['bearing'] as double?,
              timestamp: DateTime.fromMillisecondsSinceEpoch(tp['timestamp'] as int),
            ))
        .toList();

    return RunSession(
      id: map['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : null,
      status: RunStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      trackPoints: trackPoints,
      totalDistance: map['totalDistance'] as double,
      elapsedTime: Duration(milliseconds: map['elapsedTime'] as int),
      averageBpm: map['averageBpm'] as int?,
      notes: map['notes'] as String?,
    );
  }
}
