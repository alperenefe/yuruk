import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:yuruk/domain/entities/run_session.dart';
import 'package:yuruk/domain/repositories/location_repository.dart';
import 'package:yuruk/domain/usecases/start_run_session.dart';
import 'package:yuruk/domain/exceptions/location_exceptions.dart';

import 'start_run_session_test.mocks.dart';

@GenerateMocks([LocationRepository])
void main() {
  group('StartRunSession', () {
    late StartRunSession startRunSession;
    late MockLocationRepository mockLocationRepository;

    setUp(() {
      mockLocationRepository = MockLocationRepository();
      startRunSession = StartRunSession(mockLocationRepository);
    });

    test('should throw LocationServiceDisabledException when location service is disabled', () async {
      when(mockLocationRepository.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      await expectLater(
        startRunSession.execute(),
        throwsA(isA<LocationServiceDisabledException>()),
      );

      verify(mockLocationRepository.isLocationServiceEnabled()).called(1);
      verifyNever(mockLocationRepository.requestPermission());
      verifyNever(mockLocationRepository.startTracking());
    });

    test('should throw LocationPermissionDeniedException when permission is denied', () async {
      when(mockLocationRepository.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockLocationRepository.requestPermission())
          .thenAnswer((_) async => false);

      await expectLater(
        startRunSession.execute(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );

      verify(mockLocationRepository.isLocationServiceEnabled()).called(1);
      verify(mockLocationRepository.requestPermission()).called(1);
      verifyNever(mockLocationRepository.startTracking());
    });

    test('should start tracking and return new RunSession when service enabled and permission granted', () async {
      when(mockLocationRepository.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockLocationRepository.requestPermission())
          .thenAnswer((_) async => true);
      when(mockLocationRepository.startTracking())
          .thenAnswer((_) async => {});

      final result = await startRunSession.execute();

      expect(result, isA<RunSession>());
      expect(result.status, RunStatus.running);
      expect(result.trackPoints, isEmpty);
      expect(result.totalDistance, 0.0);
      expect(result.endTime, isNull);

      verify(mockLocationRepository.isLocationServiceEnabled()).called(1);
      verify(mockLocationRepository.requestPermission()).called(1);
      verify(mockLocationRepository.startTracking()).called(1);
    });

    test('returned RunSession should have valid ID and timestamp', () async {
      when(mockLocationRepository.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockLocationRepository.requestPermission())
          .thenAnswer((_) async => true);
      when(mockLocationRepository.startTracking())
          .thenAnswer((_) async => {});

      final result = await startRunSession.execute();

      expect(result.id, isNotEmpty);
      expect(result.startTime.isBefore(DateTime.now().add(Duration(seconds: 1))), true);
      expect(result.elapsedTime, Duration.zero);
    });
  });
}
