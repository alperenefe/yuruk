import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yuruk/core/di/service_locator.dart';
import 'package:yuruk/domain/repositories/location_repository.dart';
import 'package:yuruk/infrastructure/gps/geolocator_location_repository.dart';
import 'package:yuruk/infrastructure/gps/simulated_location_repository.dart';

void main() {
  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('varsayılan olarak gerçek GPS kullanır', () {
    setupServiceLocator();
    expect(getIt<LocationRepository>(), isA<GeolocatorLocationRepository>());
  });

  test('useSimulatedGps true ile simüle GPS kullanır', () {
    setupServiceLocator(useSimulatedGps: true);
    expect(getIt<LocationRepository>(), isA<SimulatedLocationRepository>());
  });
}
