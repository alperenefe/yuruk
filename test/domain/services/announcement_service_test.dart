import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/domain/services/announcement_service.dart';
import 'package:yuruk/domain/entities/interval_step.dart';
import 'package:yuruk/domain/entities/interval_session.dart';
import 'package:yuruk/domain/entities/workout_plan.dart';

void main() {
  group('AnnouncementService', () {
    late AnnouncementService service;

    setUp(() {
      service = AnnouncementService();
    });

    group('Interval Announcements', () {
      test('should announce distance-based interval start', () {
        final step = IntervalStep.distance(
          id: '1',
          meters: 400,
          name: 'Hızlı',
        );

        final announcement = service.getIntervalStepStartAnnouncement(step);
        
        expect(announcement, '400 metre hızlı başladı');
      });

      test('should announce time-based interval start', () {
        final step = IntervalStep.time(
          id: '1',
          duration: Duration(minutes: 2, seconds: 30),
          name: 'Tempo',
        );

        final announcement = service.getIntervalStepStartAnnouncement(step);
        
        expect(announcement, '2 dakika 30 saniye tempo başladı');
      });

      test('should announce rest interval start', () {
        final step = IntervalStep.distance(
          id: '1',
          meters: 200,
          isRest: true,
        );

        final announcement = service.getIntervalStepStartAnnouncement(step);
        
        expect(announcement, 'Dinlenme başladı');
      });

      test('should announce rest interval completion', () {
        final step = IntervalStep.distance(
          id: '1',
          meters: 200,
          isRest: true,
        );
        
        final plan = WorkoutPlan(
          id: 'test',
          name: 'Test',
          steps: [step],
          createdAt: DateTime.now(),
        );
        
        final session = IntervalSession(
          workoutPlan: plan,
          stepActualDistance: 200,
          stepActualTimeSeconds: 60,
        );

        final announcement = service.getIntervalStepCompletedAnnouncement(step, session);
        
        expect(announcement, 'Dinlenme tamamlandı');
      });

      test('should announce interval completion with pace feedback when faster', () {
        final step = IntervalStep.distance(
          id: '1',
          meters: 400,
          targetPace: '5:00',
        );
        
        final plan = WorkoutPlan(
          id: 'test',
          name: 'Test',
          steps: [step],
          createdAt: DateTime.now(),
        );
        
        // 400m in 115 seconds = 4:47.5 pace → rounds to 4:48
        final session = IntervalSession(
          workoutPlan: plan,
          stepActualDistance: 400,
          stepActualTimeSeconds: 115,
        );

        final announcement = service.getIntervalStepCompletedAnnouncement(step, session);
        
        expect(announcement, contains('400 metre tamamlandı'));
        expect(announcement, contains('Tempo 4:4')); // 4:47 or 4:48
        expect(announcement, contains('hedef 5:00'));
        expect(announcement, contains('saniye hızlısın'));
      });

      test('should announce interval completion with pace feedback when slower', () {
        final step = IntervalStep.distance(
          id: '1',
          meters: 400,
          targetPace: '5:00',
        );
        
        final plan = WorkoutPlan(
          id: 'test',
          name: 'Test',
          steps: [step],
          createdAt: DateTime.now(),
        );
        
        // 400m in 130 seconds = 5:25 pace (slower than 5:00)
        final session = IntervalSession(
          workoutPlan: plan,
          stepActualDistance: 400,
          stepActualTimeSeconds: 130,
        );

        final announcement = service.getIntervalStepCompletedAnnouncement(step, session);
        
        expect(announcement, contains('400 metre tamamlandı'));
        expect(announcement, contains('Tempo 5:25'));
        expect(announcement, contains('hedef 5:00'));
        expect(announcement, contains('saniye yavaşsın'));
      });

      test('should announce perfect pace', () {
        final step = IntervalStep.distance(
          id: '1',
          meters: 1000,
          targetPace: '5:00',
        );
        
        final plan = WorkoutPlan(
          id: 'test',
          name: 'Test',
          steps: [step],
          createdAt: DateTime.now(),
        );
        
        // Exactly 5:00 pace
        final session = IntervalSession(
          workoutPlan: plan,
          stepActualDistance: 1000,
          stepActualTimeSeconds: 300,
        );

        final announcement = service.getIntervalStepCompletedAnnouncement(step, session);
        
        expect(announcement, contains('Mükemmel'));
      });

      test('should announce workout completion', () {
        final announcement = service.getWorkoutCompletedAnnouncement();
        
        expect(announcement, 'Tüm intervallar tamamlandı. Harika iş!');
      });
    });
  });
}
