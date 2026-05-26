import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/run_session_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../infrastructure/gps/geolocator_location_repository.dart';
import '../../infrastructure/gps/simulated_location_repository.dart';
import '../../infrastructure/storage/sqlite_run_session_repository.dart';
import '../../infrastructure/storage/sqlite_workout_repository.dart';

final getIt = GetIt.instance;

/// Setup dependency injection
///
/// [useSimulatedGps]: Simüle GPS (yalnızca test/emülatör).
/// Varsayılan: gerçek GPS. Simülasyon için:
/// `flutter run --dart-define=USE_SIMULATED_GPS=true`
void setupServiceLocator({bool? useSimulatedGps}) {
  const simulatedFromEnv = bool.fromEnvironment(
    'USE_SIMULATED_GPS',
    defaultValue: false,
  );
  final bool shouldUseSimulatedGps = useSimulatedGps ?? simulatedFromEnv;
  
  // GPS Repository
  if (shouldUseSimulatedGps) {
    if (kDebugMode) {
      print('🎯 Using SimulatedLocationRepository (5km route with realistic pace variations)');
    }
    getIt.registerLazySingleton<LocationRepository>(
      () => SimulatedLocationRepository(),
    );
  } else {
    if (kDebugMode) {
      print('📡 Using GeolocatorLocationRepository (real GPS)');
    }
    getIt.registerLazySingleton<LocationRepository>(
      () => GeolocatorLocationRepository(),
    );
  }

  // SQLite - Phase 4
  getIt.registerLazySingleton<RunSessionRepository>(
    () => SqliteRunSessionRepository(),
  );

  // Workout Plans - Phase 7
  getIt.registerLazySingleton<WorkoutRepository>(
    () => SqliteWorkoutRepository(),
  );
}
