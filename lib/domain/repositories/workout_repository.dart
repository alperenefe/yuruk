import '../entities/workout_plan.dart';

/// Abstract repository for workout plan storage
abstract class WorkoutRepository {
  /// Save a workout plan
  Future<void> savePlan(WorkoutPlan plan);
  
  /// Get a workout plan by ID
  Future<WorkoutPlan?> getPlanById(String id);
  
  /// Get all workout plans
  Future<List<WorkoutPlan>> getAllPlans();
  
  /// Delete a workout plan
  Future<void> deletePlan(String id);
  
  /// Update a workout plan
  Future<void> updatePlan(WorkoutPlan plan);
}
