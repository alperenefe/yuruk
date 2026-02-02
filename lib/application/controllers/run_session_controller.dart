import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../domain/usecases/start_run_session.dart';
import '../../domain/usecases/stop_run_session.dart';
import '../../domain/usecases/update_run_session.dart';
import '../../domain/exceptions/location_exceptions.dart';

class RunSessionState {
  final RunSession? currentSession;
  final bool isRunning;
  final bool isLoading;
  final String? error;

  RunSessionState({
    this.currentSession,
    this.isRunning = false,
    this.isLoading = false,
    this.error,
  });

  RunSessionState copyWith({
    RunSession? currentSession,
    bool? isRunning,
    bool? isLoading,
    String? error,
  }) {
    return RunSessionState(
      currentSession: currentSession ?? this.currentSession,
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

  StreamSubscription<TrackPoint>? _locationSubscription;
  Timer? _elapsedTimer;

  RunSessionController(
    this._locationRepository,
    this._runSessionRepository,
  )   : _startRunSession = StartRunSession(_locationRepository),
        _stopRunSession = StopRunSession(_locationRepository, _runSessionRepository),
        _updateRunSession = UpdateRunSession(),
        super(RunSessionState());

  Future<void> startRun() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final session = await _startRunSession.execute();
      
      state = state.copyWith(
        currentSession: session,
        isRunning: true,
        isLoading: false,
        error: null,
      );

      _startElapsedTimer();

      _locationSubscription = _locationRepository.getLocationStream().listen(
        (trackPoint) {
          if (state.currentSession != null) {
            final updatedSession = _updateRunSession.execute(
              state.currentSession!,
              trackPoint,
            );
            state = state.copyWith(currentSession: updatedSession);
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
      final initialPosition = await _locationRepository.getCurrentPosition()
          .timeout(const Duration(seconds: 5));
      
      if (state.currentSession != null) {
        final updatedSession = _updateRunSession.execute(
          state.currentSession!,
          initialPosition,
        );
        state = state.copyWith(currentSession: updatedSession);
      }
    } catch (e) {
      // İlk pozisyon alınamazsa, stream'den geleni bekle
    }
  }

  Future<void> stopRun() async {
    try {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
      
      if (state.currentSession != null) {
        final stoppedSession = await _stopRunSession.execute(state.currentSession!);
        state = state.copyWith(
          currentSession: stoppedSession,
          isRunning: false,
          error: null,
        );
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
    super.dispose();
  }
}
