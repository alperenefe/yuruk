import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/entities/interval_session.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../domain/usecases/start_run_session.dart';
import '../../domain/usecases/stop_run_session.dart';
import '../../domain/usecases/update_run_session.dart';
import '../../domain/usecases/interval_engine.dart';
import '../../domain/exceptions/location_exceptions.dart';
import '../../domain/services/announcement_service.dart';
import '../../infrastructure/tts/flutter_tts_service.dart';
import '../../infrastructure/background/foreground_task_handler.dart';
import '../../infrastructure/gps/simulated_location_repository.dart';

class RunSessionState {
  final RunSession? currentSession;
  final IntervalSession? intervalSession;
  final bool isRunning;
  final bool isLoading;
  final String? error;

  RunSessionState({
    this.currentSession,
    this.intervalSession,
    this.isRunning = false,
    this.isLoading = false,
    this.error,
  });

  RunSessionState copyWith({
    RunSession? currentSession,
    IntervalSession? intervalSession,
    bool? isRunning,
    bool? isLoading,
    String? error,
  }) {
    return RunSessionState(
      currentSession: currentSession ?? this.currentSession,
      intervalSession: intervalSession ?? this.intervalSession,
      isRunning: isRunning ?? this.isRunning,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RunSessionController extends StateNotifier<RunSessionState> {
  final LocationRepository _locationRepository;
  final RunSessionRepository _runSessionRepository;
  final StartRunSession _startRunSession;
  final StopRunSession _stopRunSession;
  final UpdateRunSession _updateRunSession;
  final FlutterTtsService _ttsService = FlutterTtsService();
  final AnnouncementService _announcementService = AnnouncementService();
  final IntervalEngine _intervalEngine = IntervalEngine();

  StreamSubscription<TrackPoint>? _locationSubscription;
  Timer? _elapsedTimer;

  RunSessionController(
    this._locationRepository,
    this._runSessionRepository,
  )   : _startRunSession = StartRunSession(_locationRepository),
        _stopRunSession = StopRunSession(_locationRepository, _runSessionRepository),
        _updateRunSession = UpdateRunSession(),
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

      // Start foreground service for background tracking (skip for simulated GPS)
      final isSimulated = _locationRepository is SimulatedLocationRepository;
      if (!isSimulated) {
        await ForegroundTaskManager.startService();
      } else if (kDebugMode) {
        print('⏩ Skipping foreground service (simulated GPS)');
      }
      
      _startElapsedTimer();

      _locationSubscription = _locationRepository.getLocationStream().listen(
        (trackPoint) {
          if (state.currentSession != null) {
            final oldPointCount = state.currentSession!.trackPoints.length;
            final updatedSession = _updateRunSession.execute(
              state.currentSession!,
              trackPoint,
            );
            final newPointCount = updatedSession.trackPoints.length;
            
            if (kDebugMode) {
              if (newPointCount > oldPointCount) {
                print('✅ Point ACCEPTED (total: $newPointCount)');
              } else {
                print('❌ Point REJECTED');
              }
            }
            
            state = state.copyWith(currentSession: updatedSession);
            
            // Update interval engine if active
            if (state.intervalSession != null) {
              _updateIntervalSession(updatedSession);
            }
          }
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      );
      
      _fetchInitialPosition();
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

  Future<void> _fetchInitialPosition() async {
    try {
      if (kDebugMode) print('🔍 Fetching initial position...');
      final initialPosition = await _locationRepository.getCurrentPosition()
          .timeout(const Duration(seconds: 5));
      
      if (kDebugMode) {
        print('✅ Initial position: ${initialPosition.accuracy.toStringAsFixed(1)}m');
      }
      
      if (state.currentSession != null) {
        final updatedSession = _updateRunSession.execute(
          state.currentSession!,
          initialPosition,
        );
        state = state.copyWith(currentSession: updatedSession);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Initial position timeout: $e');
    }
  }

  Future<void> stopRun() async {
    try {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
      
      if (state.currentSession != null) {
        final stoppedSession = await _stopRunSession.execute(state.currentSession!);
        _ttsService.speak(_announcementService.getStopAnnouncement(stoppedSession));
        
        state = state.copyWith(
          currentSession: stoppedSession,
          isRunning: false,
          error: null,
        );
      }

      // Stop foreground service (skip for simulated GPS)
      final isSimulated = _locationRepository is SimulatedLocationRepository;
      if (!isSimulated) {
        await ForegroundTaskManager.stopService();
      }
      
      await _locationSubscription?.cancel();
      _locationSubscription = null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
