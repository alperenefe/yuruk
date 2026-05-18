import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/gps_filter_params.dart';
import '../../core/filters/gps_filter_pipeline.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/entities/run_session.dart';

class ComparisonState {
  final List<GpsFilterParams> configs;
  final List<FilteredTrackResult> results;
  final List<TrackPoint> rawPoints;
  final String? runLabel;
  final String? errorMessage;
  final bool isLoaded;

  const ComparisonState({
    this.configs = const [],
    this.results = const [],
    this.rawPoints = const [],
    this.runLabel,
    this.errorMessage,
    this.isLoaded = false,
  });

  ComparisonState copyWith({
    List<GpsFilterParams>? configs,
    List<FilteredTrackResult>? results,
    List<TrackPoint>? rawPoints,
    String? runLabel,
    String? errorMessage,
    bool clearError = false,
    bool? isLoaded,
  }) {
    return ComparisonState(
      configs: configs ?? this.configs,
      results: results ?? this.results,
      rawPoints: rawPoints ?? this.rawPoints,
      runLabel: runLabel ?? this.runLabel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class ComparisonSessionController extends StateNotifier<ComparisonState> {
  ComparisonSessionController()
      : super(ComparisonState(configs: List.of(GpsFilterParams.allPresets)));

  void loadRunSession(RunSession session) {
    final rawPoints = session.labInputPoints;
    if (rawPoints.isEmpty) {
      state = state.copyWith(errorMessage: 'Bu koşuda kayıtlı nokta yok.');
      return;
    }
    final results = _runAllPipelines(rawPoints, state.configs);
    final label =
        '${session.startTime.day}.${session.startTime.month}.${session.startTime.year} '
        '— ${(session.totalDistance / 1000).toStringAsFixed(2)} km';
    state = state.copyWith(
      results: results,
      rawPoints: rawPoints,
      runLabel: label,
      isLoaded: true,
      clearError: true,
    );
  }

  void addConfig(GpsFilterParams config) {
    final updated = [...state.configs, config];
    final results = state.isLoaded
        ? _runAllPipelines(state.rawPoints, updated)
        : <FilteredTrackResult>[];
    state = state.copyWith(configs: updated, results: results);
  }

  void removeConfig(int index) {
    if (index < 0 || index >= state.configs.length) return;
    final updated = List<GpsFilterParams>.from(state.configs)..removeAt(index);
    final results = state.isLoaded
        ? _runAllPipelines(state.rawPoints, updated)
        : <FilteredTrackResult>[];
    state = state.copyWith(configs: updated, results: results);
  }

  void updateConfig(int index, GpsFilterParams newParams) {
    if (index < 0 || index >= state.configs.length) return;
    final updated = List<GpsFilterParams>.from(state.configs)..[index] = newParams;
    final results = state.isLoaded
        ? _runAllPipelines(state.rawPoints, updated)
        : <FilteredTrackResult>[];
    state = state.copyWith(configs: updated, results: results);
  }

  void reorderConfig(int oldIndex, int newIndex) {
    final updated = List<GpsFilterParams>.from(state.configs);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    final results = state.isLoaded
        ? _runAllPipelines(state.rawPoints, updated)
        : <FilteredTrackResult>[];
    state = state.copyWith(configs: updated, results: results);
  }

  List<FilteredTrackResult> _runAllPipelines(
    List<TrackPoint> rawPoints,
    List<GpsFilterParams> configs,
  ) {
    return configs.map((config) {
      final pipeline = GpsFilterPipeline(config);
      for (final point in rawPoints) {
        pipeline.processPoint(point);
      }
      return pipeline.result;
    }).toList();
  }

  void reset() {
    state = ComparisonState(configs: List.of(state.configs));
  }
}

final comparisonSessionProvider =
    StateNotifierProvider<ComparisonSessionController, ComparisonState>(
  (ref) => ComparisonSessionController(),
);
