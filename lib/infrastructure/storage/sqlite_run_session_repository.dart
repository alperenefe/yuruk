import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/named_track_segment.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../database/database_helper.dart';

class SqliteRunSessionRepository implements RunSessionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  static List<Map<String, dynamic>> _encodeTrackPoints(List<TrackPoint> points) {
    return points
        .map(
          (tp) => {
            'latitude': tp.latitude,
            'longitude': tp.longitude,
            'altitude': tp.altitude,
            'accuracy': tp.accuracy,
            'speed': tp.speed,
            'bearing': tp.bearing,
            'timestamp': tp.timestamp.millisecondsSinceEpoch,
          },
        )
        .toList();
  }

  static List<TrackPoint> _decodeTrackPoints(List<dynamic> list) {
    return list
        .map(
          (tp) => TrackPoint(
            latitude: (tp['latitude'] as num).toDouble(),
            longitude: (tp['longitude'] as num).toDouble(),
            altitude: (tp['altitude'] as num).toDouble(),
            accuracy: (tp['accuracy'] as num).toDouble(),
            speed: (tp['speed'] as num).toDouble(),
            bearing: tp['bearing'] == null
                ? null
                : (tp['bearing'] as num).toDouble(),
            timestamp: DateTime.fromMillisecondsSinceEpoch(tp['timestamp'] as int),
          ),
        )
        .toList();
  }

  static String _encodeFilterExports(List<NamedTrackSegment> segments) {
    final list = segments
        .map(
          (s) => {
            'name': s.name,
            'points': _encodeTrackPoints(s.points),
          },
        )
        .toList();
    return jsonEncode(list);
  }

  static List<NamedTrackSegment> _decodeFilterExports(List<dynamic> list) {
    return list
        .map(
          (e) => NamedTrackSegment(
            name: e['name'] as String,
            points: _decodeTrackPoints(e['points'] as List<dynamic>),
          ),
        )
        .toList();
  }

  @override
  Future<void> saveSession(RunSession session) async {
    final db = await _databaseHelper.database;

    final trackPointsJson = _encodeTrackPoints(session.trackPoints);
    final rawJson = _encodeTrackPoints(session.rawTrackPoints);
    final filterJson = _encodeFilterExports(session.filterExportTracks);

    await db.insert(
      'run_sessions',
      {
        'id': session.id,
        'startTime': session.startTime.millisecondsSinceEpoch,
        'endTime': session.endTime?.millisecondsSinceEpoch,
        'status': session.status.name,
        'trackPoints': jsonEncode(trackPointsJson),
        'rawTrackPoints': jsonEncode(rawJson),
        'filterExports': filterJson,
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
    final trackPoints = _decodeTrackPoints(trackPointsJson);

    final rawRaw = map['rawTrackPoints'];
    final List<TrackPoint> rawTrackPoints;
    if (rawRaw != null && (rawRaw as String).isNotEmpty) {
      rawTrackPoints = _decodeTrackPoints(jsonDecode(rawRaw) as List);
    } else {
      rawTrackPoints = const [];
    }

    final filterRaw = map['filterExports'];
    final List<NamedTrackSegment> filterExportTracks;
    if (filterRaw != null && (filterRaw as String).isNotEmpty) {
      filterExportTracks =
          _decodeFilterExports(jsonDecode(filterRaw) as List<dynamic>);
    } else {
      filterExportTracks = const [];
    }

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
      rawTrackPoints: rawTrackPoints,
      filterExportTracks: filterExportTracks,
      totalDistance: (map['totalDistance'] as num).toDouble(),
      elapsedTime: Duration(milliseconds: map['elapsedTime'] as int),
      averageBpm: map['averageBpm'] as int?,
      notes: map['notes'] as String?,
    );
  }
}
