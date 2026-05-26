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
import '../../core/crash/crash_reporting.dart';
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
    bool clearError = false,
    List<FilteredTrackResult>? algorithmResults,
  }) {
    return RunSessionState(
      currentSession: currentSession ?? this.currentSession,
      intervalSession: intervalSession ?? this.intervalSession,
      isRunning: isRunning ?? this.isRunning,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
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

  /// startRun tamamlanmadan stopRun çağrılırsa eski start iptal edilir.
  int _runGeneration = 0;
  bool _isStopping = false;

  RunSessionController(
    this._locationRepository,
    this._runSessionRepository,
  )   : _startRunSession = StartRunSession(_locationRepository),
        _stopRunSession = StopRunSession(_locationRepository, _runSessionRepository),
        super(RunSessionState()) {
    _ttsService.initialize();
  }

  Future<void> _teardownTracking() async {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    try {
      await _locationRepository.stopTracking();
    } catch (e, st) {
      CrashReporting.captureException(e, stackTrace: st, hint: 'stop_tracking');
    }
    final isSimulated = _locationRepository is SimulatedLocationRepository;
    if (!isSimulated) {
      await ForegroundTaskManager.stopServiceSafe();
    }
  }

  Future<void> startRun({WorkoutPlan? workoutPlan}) async {
    if (state.isLoading || _isStopping) return;

    final generation = ++_runGeneration;

    await _teardownTracking();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      algorithmResults: const [],
      isRunning: false,
    );

    try {
      final session = await _startRunSession.execute();

      if (generation != _runGeneration) {
        await _locationRepository.stopTracking();
        return;
      }

      state = state.copyWith(
        currentSession: session,
        isRunning: true,
        isLoading: false,
        clearError: true,
        algorithmResults: const [],
        intervalSession: null,
      );

      if (workoutPlan != null) {
        final intervalSession = IntervalSession(workoutPlan: workoutPlan);
        final startedInterval = _intervalEngine.start(intervalSession);
        state = state.copyWith(intervalSession: startedInterval);

        if (startedInterval.currentStep != null) {
          _ttsService.speak(_announcementService.getIntervalStepStartAnnouncement(
            startedInterval.currentStep!,
          ));
        }
      } else {
        _ttsService.speak(_announcementService.getStartAnnouncement());
      }

      if (generation != _runGeneration) {
        await _teardownTracking();
        state = state.copyWith(isRunning: false, isLoading: false);
        return;
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

      final listenGeneration = generation;
      _locationSubscription = _locationRepository.getLocationStream().listen(
        (trackPoint) {
          if (listenGeneration != _runGeneration || !state.isRunning) return;
          _comparator.process(trackPoint);
          final results = _comparator.results;

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
            state = state.copyWith(currentSession: updatedSession, algorithmResults: results);

            if (state.intervalSession != null) {
              _updateIntervalSession(updatedSession);
            }
          }
        },
        onError: (error, stackTrace) {
          if (listenGeneration != _runGeneration) return;
          CrashReporting.captureException(error, stackTrace: stackTrace, hint: 'gps_stream');
          state = state.copyWith(error: error.toString());
        },
      );
    } on LocationServiceDisabledException catch (e) {
      if (generation == _runGeneration) {
        state = state.copyWith(error: e.message, isLoading: false, isRunning: false);
      }
    } on LocationPermissionDeniedException catch (e) {
      if (generation == _runGeneration) {
        state = state.copyWith(error: e.message, isLoading: false, isRunning: false);
      }
    } catch (e, st) {
      if (generation == _runGeneration) {
        CrashReporting.captureException(e, stackTrace: st, hint: 'start_run');
        state = state.copyWith(
          error: 'Bir hata oluştu: ${e.toString()}',
          isLoading: false,
          isRunning: false,
        );
      }
    } finally {
      if (generation == _runGeneration && state.isLoading && !state.isRunning) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void _updateIntervalSession(RunSession runSession) {
    final (updatedInterval, events) = _intervalEngine.update(runSession);
    state = state.copyWith(intervalSession: updatedInterval);

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
    if (_isStopping) return;
    _isStopping = true;
    _runGeneration++;

    state = state.copyWith(isLoading: true);

    await _teardownTracking();

    try {
      if (state.currentSession != null && state.isRunning) {
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
          clearError: true,
        );
      } else {
        state = state.copyWith(isRunning: false, clearError: true);
      }
    } catch (e, st) {
      CrashReporting.captureException(e, stackTrace: st, hint: 'stop_run');
      state = state.copyWith(isRunning: false, error: e.toString());
    } finally {
      _isStopping = false;
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _runGeneration++;
    _elapsedTimer?.cancel();
    _locationSubscription?.cancel();
    _ttsService.dispose();
    super.dispose();
  }
}
