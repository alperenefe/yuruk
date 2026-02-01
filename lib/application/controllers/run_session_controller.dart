import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../domain/usecases/start_run_session.dart';
import '../../domain/usecases/stop_run_session.dart';
import '../../domain/usecases/update_run_session.dart';

class RunSessionState {
  final RunSession? currentSession;
  final bool isRunning;
  final String? error;

  RunSessionState({
    this.currentSession,
    this.isRunning = false,
    this.error,
  });

  RunSessionState copyWith({
    RunSession? currentSession,
    bool? isRunning,
    String? error,
  }) {
    return RunSessionState(
      currentSession: currentSession ?? this.currentSession,
      isRunning: isRunning ?? this.isRunning,
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

  RunSessionController(
    this._locationRepository,
    this._runSessionRepository,
  )   : _startRunSession = StartRunSession(_locationRepository),
        _stopRunSession = StopRunSession(_locationRepository, _runSessionRepository),
        _updateRunSession = UpdateRunSession(),
        super(RunSessionState());

  Future<void> startRun() async {
    try {
      final session = await _startRunSession.execute();
      state = state.copyWith(
        currentSession: session,
        isRunning: true,
        error: null,
      );

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
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopRun() async {
    try {
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
    _locationSubscription?.cancel();
    super.dispose();
  }
}
