import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/domain/entities/interval_step.dart';
import 'package:yuruk/domain/entities/interval_session.dart';
import 'package:yuruk/domain/entities/workout_plan.dart';
import 'package:yuruk/domain/entities/run_session.dart';
import 'package:yuruk/domain/usecases/interval_engine.dart';

// Helper to create test run session
RunSession createTestRunSession({
  required double totalDistance,
  required Duration elapsedTime,
}) {
  return RunSession(
    id: 'test-run',
    startTime: DateTime.now(),
    status: RunStatus.running,
    trackPoints: const [],
    totalDistance: totalDistance,
    elapsedTime: elapsedTime,
  );
}

void main() {
  group('IntervalEngine', () {
    late IntervalEngine engine;
    late WorkoutPlan testPlan;

    setUp(() {
      engine = IntervalEngine();
      
      // Create a test plan: 400m fast, 200m rest, 400m fast
      testPlan = WorkoutPlan(
        id: 'test-plan',
        name: 'Test Plan',
        createdAt: DateTime.now(),
        steps: [
          IntervalStep.distance(
            id: 'step1',
            meters: 400,
            name: 'Fast',
            isRest: false,
          ),
          IntervalStep.distance(
            id: 'step2',
            meters: 200,
            name: 'Rest',
            isRest: true,
          ),
          IntervalStep.distance(
            id: 'step3',
            meters: 400,
            name: 'Fast',
            isRest: false,
          ),
        ],
      );
    });

    test('should start interval session', () {
      final session = IntervalSession(workoutPlan: testPlan);
      final started = engine.start(session);

      expect(started.status, IntervalSessionStatus.inProgress);
      expect(started.currentStepIndex, 0);
      expect(started.currentStepProgress, 0);
      expect(started.stepStartDistance, 0);
      expect(started.stepStartTimeSeconds, 0);
    });

    test('should transition to second step after 400m', () {
      // Start session
      final session = IntervalSession(workoutPlan: testPlan);
      engine.start(session);

      // Simulate running 400m (first step target)
      final runSession = createTestRunSession(
        totalDistance: 400.0,
        elapsedTime: Duration(minutes: 2),
      );

      final (updatedSession, events) = engine.update(runSession);

      // Should complete first step and start second
      expect(updatedSession.currentStepIndex, 1); // Step 2
      expect(updatedSession.stepStartDistance, 400.0); // Offset = 400m
      expect(updatedSession.currentStepProgress, 0); // Reset for new step
      expect(events.length, 2); // StepCompleted + StepStarted
      expect(events[0], isA<IntervalStepCompleted>());
      expect(events[1], isA<IntervalStepStarted>());
    });

    test('should calculate relative progress for second step', () {
      // Start session
      final session = IntervalSession(workoutPlan: testPlan);
      engine.start(session);

      // Complete first step (400m)
      engine.update(createTestRunSession(
        totalDistance: 400.0,
        elapsedTime: Duration(minutes: 2),
      ));

      // Now at second step (200m rest), run 100m more (total = 500m)
      final (updatedSession, _) = engine.update(createTestRunSession(
        totalDistance: 500.0, // Total distance
        elapsedTime: Duration(minutes: 3),
      ));

      // Progress should be RELATIVE: 500 - 400 = 100m
      expect(updatedSession.currentStepProgress, 100.0);
      expect(updatedSession.currentStepIndex, 1); // Still on step 2
    });

    test('should complete all three steps correctly', () {
      final session = IntervalSession(workoutPlan: testPlan);
      engine.start(session);

      // Step 1: 400m
      var (updatedSession, events) = engine.update(createTestRunSession(
        totalDistance: 400.0,
        elapsedTime: Duration(minutes: 2),
      ));
      expect(updatedSession.currentStepIndex, 1);
      expect(updatedSession.stepStartDistance, 400.0);

      // Step 2: 200m (total = 600m)
      (updatedSession, events) = engine.update(createTestRunSession(
        totalDistance: 600.0,
        elapsedTime: Duration(minutes: 3),
      ));
      expect(updatedSession.currentStepIndex, 2);
      expect(updatedSession.stepStartDistance, 600.0);

      // Step 3: 400m (total = 1000m)
      (updatedSession, events) = engine.update(createTestRunSession(
        totalDistance: 1000.0,
        elapsedTime: Duration(minutes: 5),
      ));
      expect(updatedSession.status, IntervalSessionStatus.completed);
      expect(events.any((e) => e is IntervalWorkoutCompleted), true);
    });

    test('should handle time-based intervals with offset', () {
      final timePlan = WorkoutPlan(
        id: 'time-plan',
        name: 'Time Plan',
        createdAt: DateTime.now(),
        steps: [
          IntervalStep.time(
            id: 'step1',
            duration: Duration(minutes: 2),
            name: 'Fast',
          ),
          IntervalStep.time(
            id: 'step2',
            duration: Duration(minutes: 1),
            name: 'Rest',
          ),
        ],
      );

      final session = IntervalSession(workoutPlan: timePlan);
      engine.start(session);

      // Complete first step (2 minutes = 120 seconds)
      var (updatedSession, _) = engine.update(createTestRunSession(
        totalDistance: 500.0,
        elapsedTime: Duration(seconds: 120),
      ));
      expect(updatedSession.currentStepIndex, 1);
      expect(updatedSession.stepStartTimeSeconds, 120);

      // Progress in second step (30 seconds more, total = 150s)
      (updatedSession, _) = engine.update(createTestRunSession(
        totalDistance: 700.0,
        elapsedTime: Duration(seconds: 150),
      ));
      
      // Relative time: 150 - 120 = 30 seconds
      expect(updatedSession.currentStepProgress, 30.0);
    });
  });
}
