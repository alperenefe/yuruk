import 'package:uuid/uuid.dart';
import '../entities/run_session.dart';
import '../repositories/location_repository.dart';

class StartRunSession {
  final LocationRepository locationRepository;
  final Uuid _uuid = const Uuid();

  StartRunSession(this.locationRepository);

  Future<RunSession> execute() async {
    final hasPermission = await locationRepository.requestPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    final isEnabled = await locationRepository.isLocationServiceEnabled();
    if (!isEnabled) {
      throw Exception('Location service is disabled');
    }

    await locationRepository.startTracking();

    return RunSession(
      id: _uuid.v4(),
      startTime: DateTime.now(),
      status: RunStatus.running,
      trackPoints: const [],
      totalDistance: 0,
      elapsedTime: Duration.zero,
    );
  }
}
