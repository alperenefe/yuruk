import '../entities/training_program.dart';
import '../entities/scheduled_day.dart';

abstract class TrainingProgramRepository {
  Future<void> saveProgram(TrainingProgram program);

  Future<TrainingProgram?> getActiveProgram();

  Future<TrainingProgram?> getProgramById(String id);

  Future<void> setActiveProgram(String programId);

  Future<void> deactivateAll();

  Future<void> updateDayStatus(String dayId, ScheduledDayStatus status);

  Future<void> deleteProgram(String id);

  /// Aktif hedef planında bu antrenman etkinliği kullanılıyorsa planı döner.
  Future<TrainingProgram?> getActiveProgramReferencingWorkoutPlan(
    String workoutPlanId,
  );

  /// Gün kayıtlarındaki antrenman bağlantısını kaldırır (etkinlik silinince).
  Future<void> clearWorkoutPlanReferences(String workoutPlanId);
}
