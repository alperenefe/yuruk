import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:yuruk/domain/entities/run_session.dart';
import 'package:yuruk/domain/entities/track_point.dart';
import 'package:yuruk/domain/repositories/run_session_repository.dart';
import 'package:yuruk/domain/usecases/stop_run_session.dart';

import 'stop_run_session_test.mocks.dart';

@GenerateMocks([RunSessionRepository])
void main() {
  late MockRunSessionRepository repository;
  late StopRunSession useCase;

  setUp(() {
    repository = MockRunSessionRepository();
    useCase = StopRunSession(repository);
  });

  test('saves stopped session before returning', () async {
    final start = DateTime(2026, 6, 10, 8, 0);
    final session = RunSession(
      id: 'run-1',
      startTime: start,
      status: RunStatus.running,
      trackPoints: [
        TrackPoint(
          latitude: 41.0,
          longitude: 29.0,
          altitude: 0,
          accuracy: 5,
          speed: 3,
          timestamp: start,
        ),
      ],
      totalDistance: 1200,
      elapsedTime: const Duration(minutes: 6),
    );

    when(repository.saveSession(any)).thenAnswer((_) async {});

    final stopped = await useCase.execute(session);

    expect(stopped.status, RunStatus.stopped);
    expect(stopped.endTime, isNotNull);
    verify(repository.saveSession(stopped)).called(1);
    verifyNoMoreInteractions(repository);
  });
}
