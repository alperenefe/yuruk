import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/named_track_segment.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/entities/interval_session.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../domain/usecases/start_run_session.dart';
import '../../domain/usecases/stop_run_session.dart';
import '../../domain/usecases/interval_engine.dart';
import '../../domain/exceptions/location_exceptions.dart';
import '../../domain/services/announcement_service.dart';
import '../../infrastructure/tts/flutter_tts_service.dart';
import '../../infrastructure/background/foreground_task_handler.dart';
import '../../infrastructure/gps/simulated_location_repository.dart';
import '../../core/filters/gps_filter_pipeline.dart';
import '../../core/filters/live_algorithm_comparator.dart';

class RunSessionState {
  final RunSession? currentSession;
  final IntervalSession? intervalSession;
  final bool isRunning;
  final bool isLoading;
  final String? error;
  final List<FilteredTrackResult> algorithmResults;

  RunSessionState({
    this.currentSession,
    this.intervalSession,
    this.isRunning = false,
    this.isLoading = false,
    this.error,
    this.algorithmResults = const [],
  });

  RunSessionState copyWith({
    RunSession? currentSession,
    IntervalSession? intervalSession,
    bool? isRunning,
    bool? isLoading,
    String? error,
    List<FilteredTrackResult>? algorithmResults,
  }) {
    return RunSessionState(
      currentSession: currentSession ?? this.currentSession,
      intervalSession: intervalSession ?? this.intervalSession,
      isRunning: isRunning ?? this.isRunning,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      algorithmResults: algorithmResults ?? this.algorithmResults,
    );
  }
}

class RunSessionController extends StateNotifier<RunSessionState> {
  final LocationRepository _locationRepository;
  final RunSessionRepository _runSessionRepository;
  final StartRunSession _startRunSession;
  final StopRunSession _stopRunSession;
  final FlutterTtsService _ttsService = FlutterTtsService();
  final AnnouncementService _announcementService = AnnouncementService();
  final IntervalEngine _intervalEngine = IntervalEngine();

  StreamSubscription<TrackPoint>? _locationSubscription;
  Timer? _elapsedTimer;

  final LiveAlgorithmComparator _comparator = LiveAlgorithmComparator();

  RunSessionController(
    this._locationRepository,
    this._runSessionRepository,
  )   : _startRunSession = StartRunSession(_locationRepository),
        _stopRunSession = StopRunSession(_locationRepository, _runSessionRepository),
        super(RunSessionState()) {
    _ttsService.initialize();
  }

  Future<void> startRun({WorkoutPlan? workoutPlan}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final session = await _startRunSession.execute();
      
      state = state.copyWith(
        currentSession: session,
        isRunning: true,
        isLoading: false,
        error: null,
      );

      // Start interval session if workout plan provided
      if (workoutPlan != null) {
        final intervalSession = IntervalSession(workoutPlan: workoutPlan);
        final startedInterval = _intervalEngine.start(intervalSession);
        state = state.copyWith(intervalSession: startedInterval);
        
        // Announce first step
        if (startedInterval.currentStep != null) {
          _ttsService.speak(_announcementService.getIntervalStepStartAnnouncement(
            startedInterval.currentStep!,
          ));
        }
      } else {
        // Regular run without intervals
        _ttsService.speak(_announcementService.getStartAnnouncement());
      }

      _comparator.reset();

      final isSimulated = _locationRepository is SimulatedLocationRepository;
      if (!isSimulated) {
        try {
          await ForegroundTaskManager.startService();
        } catch (_) {}
      } else if (kDebugMode) {
        print('⏩ Skipping foreground service (simulated GPS)');
      }

      _startElapsedTimer();

      _locationSubscription = _locationRepository.getLocationStream().listen(
        (trackPoint) {
          if (!state.isRunning) return;
          _comparator.process(trackPoint);
          final results = _comparator.results;
          state = state.copyWith(algorithmResults: results);

          if (state.currentSession != null) {
            final primary = _comparator.primaryResult;
            final rawList = List<TrackPoint>.from(state.currentSession!.rawTrackPoints)
              ..add(trackPoint);
            final updatedSession = state.currentSession!.copyWith(
              trackPoints: List<TrackPoint>.from(primary.points),
              rawTrackPoints: rawList,
              totalDistance: primary.totalDistance,
              elapsedTime: state.currentSession!.elapsedTime,
            );
            state = state.copyWith(currentSession: updatedSession);

            if (state.intervalSession != null) {
              _updateIntervalSession(updatedSession);
            }
          }
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      );
    } on LocationServiceDisabledException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } on LocationPermissionDeniedException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Bir hata oluştu: ${e.toString()}', isLoading: false);
    }
  }

  void _updateIntervalSession(RunSession runSession) {
    final (updatedInterval, events) = _intervalEngine.update(runSession);
    state = state.copyWith(intervalSession: updatedInterval);
    
    // Process events
    for (final event in events) {
      if (event is IntervalStepCompleted) {
        if (kDebugMode) print('🏁 Interval step ${event.stepIndex} completed');
        _ttsService.speak(_announcementService.getIntervalStepCompletedAnnouncement(
          event.step,
          updatedInterval,
        ));
      } else if (event is IntervalStepStarted) {
        if (kDebugMode) print('🚀 Interval step ${event.stepIndex} started');
        _ttsService.speak(_announcementService.getIntervalStepStartAnnouncement(
          event.step,
        ));
      } else if (event is IntervalMidStepFeedback) {
        if (kDebugMode) print('📊 Mid-step feedback at 50%');
        final feedback = _announcementService.getMidStepFeedbackAnnouncement(
          event.step,
          updatedInterval,
        );
        if (feedback.isNotEmpty) {
          _ttsService.speak(feedback);
        }
      } else if (event is IntervalWorkoutCompleted) {
        if (kDebugMode) print('🎉 Workout completed!');
        _ttsService.speak(_announcementService.getWorkoutCompletedAnnouncement());
      }
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.currentSession != null && state.isRunning) {
        final elapsed = DateTime.now().difference(state.currentSession!.startTime);
        final updatedSession = state.currentSession!.copyWith(
          elapsedTime: elapsed,
        );
        state = state.copyWith(currentSession: updatedSession);
      }
    });
  }

  Future<void> stopRun() async {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    try {
      if (state.currentSession != null) {
        final filterExports = state.algorithmResults
            .map(
              (r) => NamedTrackSegment(
                name: r.params.name,
                points: List<TrackPoint>.from(r.points),
              ),
            )
            .toList();
        final sessionToSave = state.currentSession!.copyWith(
          filterExportTracks: filterExports,
        );
        state = state.copyWith(currentSession: sessionToSave);

        final stoppedSession = await _stopRunSession.execute(sessionToSave);
        _ttsService.speak(_announcementService.getStopAnnouncement(stoppedSession));

        state = state.copyWith(
          currentSession: stoppedSession,
          isRunning: false,
          error: null,
        );
      } else {
        state = state.copyWith(isRunning: false, error: null);
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, error: e.toString());
    } finally {
      final isSimulated = _locationRepository is SimulatedLocationRepository;
      if (!isSimulated) {
        await ForegroundTaskManager.stopServiceSafe();
      }
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _locationSubscription?.cancel();
    _ttsService.dispose();
    super.dispose();
  }
}
