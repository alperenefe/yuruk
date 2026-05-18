import 'package:equatable/equatable.dart';
import 'named_track_segment.dart';
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
  final List<TrackPoint> rawTrackPoints;
  final List<NamedTrackSegment> filterExportTracks;
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
    this.rawTrackPoints = const [],
    this.filterExportTracks = const [],
    required this.totalDistance,
    required this.elapsedTime,
    this.averageBpm,
    this.notes,
  });

  List<TrackPoint> get labInputPoints =>
      rawTrackPoints.isNotEmpty ? rawTrackPoints : trackPoints;

  bool get hasGpxGeometry =>
      rawTrackPoints.isNotEmpty ||
      trackPoints.isNotEmpty ||
      filterExportTracks.any((s) => s.points.isNotEmpty);

  RunSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    RunStatus? status,
    List<TrackPoint>? trackPoints,
    List<TrackPoint>? rawTrackPoints,
    List<NamedTrackSegment>? filterExportTracks,
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
      rawTrackPoints: rawTrackPoints ?? this.rawTrackPoints,
      filterExportTracks: filterExportTracks ?? this.filterExportTracks,
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
    rawTrackPoints,
    filterExportTracks,
    totalDistance,
    elapsedTime,
    averageBpm,
    notes,
  ];
}
