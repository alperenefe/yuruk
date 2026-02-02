import 'package:get_it/get_it.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../infrastructure/gps/geolocator_location_repository.dart';
import '../../infrastructure/storage/in_memory_run_session_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator({bool useMockGps = false}) {
  // Gerçek GPS - SSL sorunu çözüldü!
  getIt.registerLazySingleton<LocationRepository>(
    () => GeolocatorLocationRepository(),
  );

  getIt.registerLazySingleton<RunSessionRepository>(
    () => InMemoryRunSessionRepository(),
  );
}
