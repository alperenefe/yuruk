import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/service_locator.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../controllers/run_session_controller.dart';

final runSessionControllerProvider = StateNotifierProvider<RunSessionController, RunSessionState>((ref) {
  return RunSessionController(
    getIt<LocationRepository>(),
    getIt<RunSessionRepository>(),
  );
});
