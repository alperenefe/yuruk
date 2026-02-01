import '../../domain/entities/run_session.dart';
import '../../domain/repositories/run_session_repository.dart';

class InMemoryRunSessionRepository implements RunSessionRepository {
  final Map<String, RunSession> _sessions = {};

  @override
  Future<void> saveSession(RunSession session) async {
    _sessions[session.id] = session;
  }

  @override
  Future<RunSession?> getSessionById(String id) async {
    return _sessions[id];
  }

  @override
  Future<List<RunSession>> getAllSessions() async {
    return _sessions.values.toList();
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.remove(id);
  }
}
