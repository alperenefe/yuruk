import 'package:equatable/equatable.dart';
import 'track_point.dart';

class NamedTrackSegment extends Equatable {
  final String name;
  final List<TrackPoint> points;

  const NamedTrackSegment({
    required this.name,
    required this.points,
  });

  @override
  List<Object?> get props => [name, points];
}
