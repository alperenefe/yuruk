import 'package:equatable/equatable.dart';
import 'track_point.dart';
import '../../core/config/gps_filter_config.dart';

enum RunStatus {
  idle,
  running,
  stopped,
}

class RunSession extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final RunStatus status;
  final List<TrackPoint> trackPoints;
  final double totalDistance;
  final Duration elapsedTime;
  final int? averageBpm;
  final String? notes;

  const RunSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.trackPoints,
    required this.totalDistance,
    required this.elapsedTime,
    this.averageBpm,
    this.notes,
  });

  RunSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    RunStatus? status,
    List<TrackPoint>? trackPoints,
    double? totalDistance,
    Duration? elapsedTime,
    int? averageBpm,
    String? notes,
  }) {
    return RunSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      trackPoints: trackPoints ?? this.trackPoints,
      totalDistance: totalDistance ?? this.totalDistance,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      averageBpm: averageBpm ?? this.averageBpm,
      notes: notes ?? this.notes,
    );
  }

  double get averagePaceMinPerKm {
    if (totalDistance < GpsFilterConfig.minDistanceForPace) return 0;
    final minutes = elapsedTime.inSeconds / 60.0;
    final km = totalDistance / 1000.0;
    return minutes / km;
  }

  String get averagePaceFormatted {
    if (totalDistance < GpsFilterConfig.minDistanceForPace) return '--:--'; // 50m'den sonra göster
    final pace = averagePaceMinPerKm;
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    startTime,
    endTime,
    status,
    trackPoints,
    totalDistance,
    elapsedTime,
    averageBpm,
    notes,
  ];
}
