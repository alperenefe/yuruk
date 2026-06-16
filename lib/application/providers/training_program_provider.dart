import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/scheduled_day.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/repositories/training_program_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../infrastructure/import/training_plan_json_parser.dart';

final trainingProgramRepositoryProvider = Provider<TrainingProgramRepository>(
  (ref) => getIt<TrainingProgramRepository>(),
);

final activeTrainingProgramProvider =
    AsyncNotifierProvider<ActiveTrainingProgramNotifier, TrainingProgram?>(
  ActiveTrainingProgramNotifier.new,
);

class ActiveTrainingProgramNotifier extends AsyncNotifier<TrainingProgram?> {
  @override
  Future<TrainingProgram?> build() => _load();

  Future<TrainingProgram?> _load() =>
      ref.read(trainingProgramRepositoryProvider).getActiveProgram();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<String?> importFromJson(String raw) async {
    try {
      final result = TrainingPlanJsonParser().parse(raw);
      final workoutRepo = getIt<WorkoutRepository>();
      for (final plan in result.workoutPlans) {
        await workoutRepo.savePlan(plan);
      }
      await ref.read(trainingProgramRepositoryProvider).saveProgram(result.program);
      await refresh();
      return null;
    } on TrainingPlanParseException catch (e) {
      return e.message;
    } catch (e) {
      return 'Import hatası: $e';
    }
  }

  Future<void> markDay(ScheduledDayStatus status, String dayId) async {
    await ref.read(trainingProgramRepositoryProvider).updateDayStatus(dayId, status);
    await refresh();
  }

  Future<void> deleteActive({bool deleteLinkedWorkouts = false}) async {
    final program = state.valueOrNull;
    if (program == null) return;
    final workoutIds = program.days
        .map((d) => d.workoutPlanId)
        .whereType<String>()
        .toSet();
    await ref.read(trainingProgramRepositoryProvider).deleteProgram(program.id);
    if (deleteLinkedWorkouts) {
      final workoutRepo = getIt<WorkoutRepository>();
      for (final id in workoutIds) {
        await workoutRepo.deletePlan(id);
      }
    }
    await refresh();
  }
}

/// Koşu sekmesine aktarılacak plan (Hedef → Koş).
final pendingRunWorkoutProvider = StateProvider<WorkoutPlan?>((ref) => null);

/// Ana sekme indeksi (Hedef → Koş geçişi).
final mainTabIndexProvider = StateProvider<int>((ref) => 0);
