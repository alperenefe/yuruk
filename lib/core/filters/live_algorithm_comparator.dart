import '../../domain/entities/track_point.dart';
import '../config/gps_filter_params.dart';
import 'gps_filter_pipeline.dart';

class LiveAlgorithmComparator {
  final List<GpsFilterPipeline> _pipelines;

  LiveAlgorithmComparator({List<GpsFilterParams>? presets})
      : _pipelines = (presets ?? GpsFilterParams.allPresets)
            .map(GpsFilterPipeline.new)
            .toList();

  void process(TrackPoint raw) {
    for (final pipeline in _pipelines) {
      pipeline.processPoint(raw);
    }
  }

  List<FilteredTrackResult> get results =>
      _pipelines.map((p) => p.result).toList();

  FilteredTrackResult get primaryResult {
    final idx = _pipelines.indexWhere(
      (p) => p.params.name == GpsFilterParams.current.name,
    );
    return idx >= 0 ? _pipelines[idx].result : _pipelines[0].result;
  }

  void reset() {
    for (final pipeline in _pipelines) {
      pipeline.reset();
    }
  }
}
