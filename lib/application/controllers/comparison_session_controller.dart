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
  /// Gizli varyant indeksleri. Boş = hepsi görünür.
  final Set<int> hiddenIndices;

  const ComparisonState({
    this.configs = const [],
    this.results = const [],
    this.rawPoints = const [],
    this.runLabel,
    this.errorMessage,
    this.isLoaded = false,
    this.hiddenIndices = const {},
  });

  /// i. varyant haritada görünür mü?
  bool isVisible(int i) => !hiddenIndices.contains(i);

  /// Haritaya çizilecek görünürlük listesi.
  List<bool> get visibleConfigs =>
      List.generate(configs.length, isVisible);

  ComparisonState copyWith({
    List<GpsFilterParams>? configs,
    List<FilteredTrackResult>? results,
    List<TrackPoint>? rawPoints,
    String? runLabel,
    String? errorMessage,
    bool clearError = false,
    bool? isLoaded,
    Set<int>? hiddenIndices,
  }) {
    return ComparisonState(
      configs: configs ?? this.configs,
      results: results ?? this.results,
      rawPoints: rawPoints ?? this.rawPoints,
      runLabel: runLabel ?? this.runLabel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoaded: isLoaded ?? this.isLoaded,
      hiddenIndices: hiddenIndices ?? this.hiddenIndices,
    );
  }
}

class ComparisonSessionController extends StateNotifier<ComparisonState> {
  ComparisonSessionController()
      : super(ComparisonState(configs: List.of(GpsFilterParams.allPresets)));

  void loadRunSession(RunSession session) {
    final rawPoints = session.labInputPoints;
    if (rawPoints.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Bu koşuda kayıtlı nokta yok.',
        isLoaded: false,
        results: const [],
        rawPoints: const [],
      );
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
      hiddenIndices: const {},
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
    final hidden = _reindexHiddenAfterRemove(state.hiddenIndices, index);
    state = state.copyWith(
      configs: updated,
      results: results,
      hiddenIndices: hidden,
    );
  }

  static Set<int> _reindexHiddenAfterRemove(Set<int> hidden, int removedIndex) {
    final next = <int>{};
    for (final i in hidden) {
      if (i == removedIndex) continue;
      next.add(i > removedIndex ? i - 1 : i);
    }
    return next;
  }

  void updateConfig(int index, GpsFilterParams newParams) {
    if (index < 0 || index >= state.configs.length) return;
    final updated = List<GpsFilterParams>.from(state.configs)..[index] = newParams;
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

  /// Tek varyantı göster / gizle.
  void toggleVisibility(int index) {
    if (index < 0 || index >= state.configs.length) return;
    final updated = Set<int>.from(state.hiddenIndices);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      updated.add(index);
    }
    state = state.copyWith(hiddenIndices: updated);
  }

  /// Sadece bu varyantı göster, geri kalanı gizle.
  /// Zaten solo ise hepsini tekrar göster.
  void soloVisibility(int index) {
    if (index < 0 || index >= state.configs.length) return;
    final alreadySolo = state.hiddenIndices.length == state.configs.length - 1 &&
        !state.hiddenIndices.contains(index);
    if (alreadySolo) {
      state = state.copyWith(hiddenIndices: const {});
    } else {
      final hidden = <int>{
        for (int i = 0; i < state.configs.length; i++)
          if (i != index) i,
      };
      state = state.copyWith(hiddenIndices: hidden);
    }
  }

  /// Tüm varyantları göster.
  void showAll() => state = state.copyWith(hiddenIndices: const {});

  void reset() {
    state = ComparisonState(configs: List.of(state.configs));
  }
}

final comparisonSessionProvider =
    StateNotifierProvider<ComparisonSessionController, ComparisonState>(
  (ref) => ComparisonSessionController(),
);
