import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/infrastructure/import/training_plan_json_parser.dart';

const _sampleJson = '''
{
  "version": 1,
  "goal": {
    "name": "2400m hedef",
    "raceDate": "2026-08-15",
    "distanceMeters": 2400,
    "targetTime": "10:20",
    "targetPacePerKm": "4:35"
  },
  "meta": {
    "weeksTotal": 2,
    "daysPerWeek": 3,
    "generatedBy": "test"
  },
  "weeks": [
    {
      "weekNumber": 1,
      "days": [
        {
          "date": "2026-06-10",
          "type": "easy",
          "title": "Kolay koşu",
          "description": "Rahat",
          "targetDistanceMeters": 5000,
          "targetPacePerKm": "6:00"
        },
        {
          "date": "2026-06-12",
          "type": "interval",
          "title": "6x400",
          "workout": {
            "name": "6x400",
            "steps": [
              {"type": "distance", "meters": 400, "targetPace": "4:30", "name": "Hızlı"},
              {"type": "time", "durationSeconds": 90, "isRest": true, "name": "Dinlenme"}
            ]
          }
        },
        {
          "date": "2026-06-14",
          "type": "rest",
          "title": "Dinlenme"
        }
      ]
    }
  ]
}
''';

void main() {
  test('parses valid training plan JSON', () {
    final result = TrainingPlanJsonParser().parse(_sampleJson);
    expect(result.program.goal.distanceMeters, 2400);
    expect(result.program.goal.targetTime, '10:20');
    expect(result.program.days.length, 3);
    // 1 interval (LLM steps) + 1 easy (auto) = 2 plans; rest günü plan üretilmez
    expect(result.workoutPlans.length, 2);
    final intervalPlan = result.workoutPlans.firstWhere(
      (p) => p.steps.any((s) => s.targetPace == '4:30'),
    );
    expect(intervalPlan.steps.length, 2);
    final easyPlan = result.workoutPlans.firstWhere(
      (p) => p.name.toLowerCase().contains('kolay') ||
             p.steps.any((s) => s.name == 'Kolay koşu'),
    );
    expect(easyPlan.steps.length, 1);
    expect(easyPlan.steps.first.targetDistance, 5000);
  });

  test('rejects invalid JSON', () {
    expect(
      () => TrainingPlanJsonParser().parse('not json'),
      throwsA(isA<TrainingPlanParseException>()),
    );
  });

  test('tempo günü otomatik 3 adımlı plan üretir', () {
    const json = '''
{
  "version": 1,
  "goal": { "name": "Test", "raceDate": "2026-08-15", "distanceMeters": 2400, "targetTime": "10:20" },
  "meta": { "weeksTotal": 1, "daysPerWeek": 3 },
  "weeks": [{
    "days": [{
      "date": "2026-06-16",
      "type": "tempo",
      "title": "Tempo koşu",
      "targetDistanceMeters": 8000,
      "targetPacePerKm": "5:00"
    }]
  }]
}
''';
    final result = TrainingPlanJsonParser().parse(json);
    expect(result.workoutPlans.length, 1);
    final plan = result.workoutPlans.first;
    // Isınma + tempo + soğuma
    expect(plan.steps.length, 3);
    expect(plan.steps[0].name, 'Isınma');
    expect(plan.steps[1].name, 'Tempo');
    expect(plan.steps[1].targetPace, '5:00');
    expect(plan.steps[2].name, 'Soğuma');
  });

  test('test günü ısınma + max efor + soğuma üretir', () {
    const json = '''
{
  "version": 1,
  "goal": { "name": "Test", "raceDate": "2026-08-15", "distanceMeters": 2400, "targetTime": "10:20" },
  "meta": { "weeksTotal": 1, "daysPerWeek": 1 },
  "weeks": [{
    "days": [{
      "date": "2026-06-17",
      "type": "test",
      "title": "2400m deneme",
      "targetDistanceMeters": 2400
    }]
  }]
}
''';
    final result = TrainingPlanJsonParser().parse(json);
    expect(result.workoutPlans.length, 1);
    final plan = result.workoutPlans.first;
    expect(plan.steps.length, 3);
    expect(plan.steps[1].targetDistance, 2400);
    expect(plan.steps[1].targetPace, isNull);
  });

  test('rest günü plan üretmez', () {
    const json = '''
{
  "version": 1,
  "goal": { "name": "Test", "raceDate": "2026-08-15", "distanceMeters": 2400, "targetTime": "10:20" },
  "meta": { "weeksTotal": 1, "daysPerWeek": 1 },
  "weeks": [{
    "days": [{
      "date": "2026-06-18",
      "type": "rest",
      "title": "Dinlenme"
    }]
  }]
}
''';
    final result = TrainingPlanJsonParser().parse(json);
    expect(result.workoutPlans, isEmpty);
    expect(result.program.days.first.workoutPlanId, isNull);
  });
}
