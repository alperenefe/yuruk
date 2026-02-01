import 'package:get_it/get_it.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../infrastructure/gps/mock_location_repository.dart';
import '../../infrastructure/storage/in_memory_run_session_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<LocationRepository>(
    () => MockLocationRepository(),
  );

  getIt.registerLazySingleton<RunSessionRepository>(
    () => InMemoryRunSessionRepository(),
  );
}
