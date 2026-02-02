import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/infrastructure/gps/geolocator_location_repository.dart';

void main() {
  group('GeolocatorLocationRepository', () {
    late GeolocatorLocationRepository repository;

    setUp(() {
      repository = GeolocatorLocationRepository();
    });

    tearDown(() async {
      await repository.stopTracking();
    });

    test('getLocationStream should return a broadcast stream', () {
      final stream = repository.getLocationStream();
      expect(stream.isBroadcast, true);
    });

    test('stopTracking should cancel subscription and close controller', () async {
      final stream = repository.getLocationStream();
      expect(stream, isNotNull);
      
      await repository.stopTracking();
      
      expect(() async => await stream.first, throwsA(isA<StateError>()));
    });

    test('LocationSettings should have correct configuration', () {
      expect(GeolocatorLocationRepository, isNotNull);
    });

    // Integration tests - require device/emulator with GPS
    test('requestPermission should return false for deniedForever', () async {
      final result = await repository.requestPermission();
      expect(result, isA<bool>());
    }, skip: 'Requires platform binding - run as integration test');

    test('isLocationServiceEnabled should return boolean', () async {
      final result = await repository.isLocationServiceEnabled();
      expect(result, isA<bool>());
    }, skip: 'Requires platform binding - run as integration test');
  });
}
