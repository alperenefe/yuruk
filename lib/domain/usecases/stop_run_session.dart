import '../entities/run_session.dart';
import '../repositories/run_session_repository.dart';

class StopRunSession {
  final RunSessionRepository runSessionRepository;

  StopRunSession(this.runSessionRepository);

  /// GPS durdurma çağıran tarafta yapılır; önce diske yaz (arka plana atınca kayıp olmasın).
  Future<RunSession> execute(RunSession currentSession) async {
    final endTime = DateTime.now();
    final stoppedSession = currentSession.copyWith(
      status: RunStatus.stopped,
      endTime: endTime,
      elapsedTime: endTime.difference(currentSession.startTime),
    );

    await runSessionRepository.saveSession(stoppedSession);

    return stoppedSession;
  }
}
