import '../entities/run_session.dart';
import '../repositories/location_repository.dart';
import '../repositories/run_session_repository.dart';

class StopRunSession {
  final LocationRepository locationRepository;
  final RunSessionRepository runSessionRepository;

  StopRunSession(
    this.locationRepository,
    this.runSessionRepository,
  );

  Future<RunSession> execute(RunSession currentSession) async {
    await locationRepository.stopTracking();

    final stoppedSession = currentSession.copyWith(
      status: RunStatus.stopped,
      endTime: DateTime.now(),
    );

    await runSessionRepository.saveSession(stoppedSession);

    return stoppedSession;
  }
}
