import '../entities/run_session.dart';

abstract class RunSessionRepository {
  Future<void> saveSession(RunSession session);
  
  Future<RunSession?> getSessionById(String id);
  
  Future<List<RunSession>> getAllSessions();
  
  Future<void> deleteSession(String id);
}
