import 'package:uuid/uuid.dart';
import '../entities/run_session.dart';
import '../repositories/location_repository.dart';
import '../exceptions/location_exceptions.dart';

class StartRunSession {
  final LocationRepository locationRepository;
  final Uuid _uuid = const Uuid();

  StartRunSession(this.locationRepository);

  Future<RunSession> execute() async {
    // Konum servisi kontrolü
    final isEnabled = await locationRepository.isLocationServiceEnabled();
    if (!isEnabled) {
      throw LocationServiceDisabledException();
    }

    // Konum izni kontrolü
    final hasPermission = await locationRepository.requestPermission();
    if (!hasPermission) {
      throw LocationPermissionDeniedException();
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
