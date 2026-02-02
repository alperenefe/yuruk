import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/domain/entities/interval_step.dart';
import 'package:yuruk/domain/entities/interval_session.dart';
import 'package:yuruk/domain/entities/workout_plan.dart';

void main() {
  group('IntervalSession', () {
    late WorkoutPlan testPlan;

    setUp(() {
      testPlan = WorkoutPlan(
        id: 'test',
        name: 'Test Plan',
        steps: [
          IntervalStep.distance(id: '1', meters: 400),
          IntervalStep.distance(id: '2', meters: 200, isRest: true),
        ],
        createdAt: DateTime.now(),
      );
    });

    test('should calculate actual pace correctly', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        stepActualDistance: 1000, // 1 km
        stepActualTimeSeconds: 300, // 5 minutes
      );

      expect(session.stepActualPaceMinPerKm, 5.0);
      expect(session.stepActualPaceFormatted, '5:00');
    });

    test('should return null pace when distance < 50m', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        stepActualDistance: 30,
        stepActualTimeSeconds: 10,
      );

      expect(session.stepActualPaceMinPerKm, null);
      expect(session.stepActualPaceFormatted, null);
    });

    test('should format pace with leading zeros', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        stepActualDistance: 1000,
        stepActualTimeSeconds: 290, // 4:50
      );

      expect(session.stepActualPaceFormatted, '4:50');
    });

    test('should calculate progress percentage for distance-based step', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        currentStepIndex: 0,
        currentStepProgress: 200, // 200m out of 400m
      );

      expect(session.currentStepProgressPercentage, 50.0);
    });

    test('should calculate progress percentage for time-based step', () {
      final plan = WorkoutPlan(
        id: 'test',
        name: 'Test',
        steps: [
          IntervalStep.time(id: '1', duration: Duration(minutes: 2)),
        ],
        createdAt: DateTime.now(),
      );

      final session = IntervalSession(
        workoutPlan: plan,
        currentStepProgress: 60, // 60 seconds out of 120
      );

      expect(session.currentStepProgressPercentage, 50.0);
    });

    test('should identify current step correctly', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        currentStepIndex: 0,
      );

      expect(session.currentStep?.id, '1');
      expect(session.currentStep?.targetDistance, 400);
    });

    test('should identify next step correctly', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        currentStepIndex: 0,
      );

      expect(session.nextStep?.id, '2');
      expect(session.nextStep?.isRest, true);
    });

    test('should return null when no next step', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        currentStepIndex: 1, // Last step
      );

      expect(session.nextStep, null);
    });

    test('should check if current step is completed (distance)', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        currentStepIndex: 0,
        currentStepProgress: 400,
      );

      expect(session.isCurrentStepCompleted, true);
    });

    test('should check if all steps are completed', () {
      final session = IntervalSession(
        workoutPlan: testPlan,
        currentStepIndex: 1, // Last step
        currentStepProgress: 200, // Completed
      );

      expect(session.isAllStepsCompleted, true);
    });
  });
}
