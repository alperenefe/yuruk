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
/// [useSimulatedGps]: Force simulated GPS (useful for emulator testing)
/// - If true: Uses SimulatedLocationRepository (realistic 5km route)
/// - If false: Uses GeolocatorLocationRepository (real GPS)
/// - Default: Auto-detect (simulated in debug mode on emulator, real otherwise)
void setupServiceLocator({bool? useSimulatedGps}) {
  // Auto-detect: Use simulated GPS in debug mode (for emulator testing)
  final bool shouldUseSimulatedGps = useSimulatedGps ?? kDebugMode;
  
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
