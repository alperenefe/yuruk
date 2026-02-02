import '../entities/interval_session.dart';
import '../entities/interval_step.dart';
import '../entities/run_session.dart';

/// Events emitted by the interval engine
abstract class IntervalEvent {}

class IntervalStepStarted extends IntervalEvent {
  final IntervalStep step;
  final int stepIndex;
  IntervalStepStarted(this.step, this.stepIndex);
}

class IntervalStepCompleted extends IntervalEvent {
  final IntervalStep step;
  final int stepIndex;
  IntervalStepCompleted(this.step, this.stepIndex);
}

class IntervalMidStepFeedback extends IntervalEvent {
  final IntervalStep step;
  final int stepIndex;
  IntervalMidStepFeedback(this.step, this.stepIndex);
}

class IntervalWorkoutCompleted extends IntervalEvent {}

/// Core interval training engine
/// 
/// Receives distance/time updates and determines interval transitions
/// Pure domain logic - no dependencies on UI, GPS, or audio
class IntervalEngine {
  IntervalSession? _currentSession;
  final List<IntervalEvent> _events = [];
  final Set<int> _midStepFeedbackGiven = {}; // Track which steps got 50% feedback

  /// Start a new interval session
  IntervalSession start(IntervalSession session) {
    _currentSession = session.copyWith(
      status: IntervalSessionStatus.inProgress,
      startTime: DateTime.now(),
      currentStepIndex: 0,
      currentStepProgress: 0,
    );
    
    // Emit start event for first step
    if (_currentSession!.currentStep != null) {
      _events.add(IntervalStepStarted(_currentSession!.currentStep!, 0));
    }
    
    return _currentSession!;
  }

  /// Update session with new GPS data from RunSession
  /// 
  /// Returns updated IntervalSession and any events that occurred
  (IntervalSession, List<IntervalEvent>) update(RunSession runSession) {
    if (_currentSession == null || _currentSession!.status != IntervalSessionStatus.inProgress) {
      return (_currentSession ?? _createEmptySession(), []);
    }

    _events.clear();
    
    final currentStep = _currentSession!.currentStep;
    if (currentStep == null) {
      return (_currentSession!, []);
    }

    // Calculate RELATIVE progress (not absolute!)
    double newProgress;
    double actualDistance;
    int actualTime;
    
    if (currentStep.type == IntervalType.distance) {
      // Distance covered SINCE step started
      newProgress = runSession.totalDistance - _currentSession!.stepStartDistance;
      actualDistance = newProgress;
      actualTime = runSession.elapsedTime.inSeconds - _currentSession!.stepStartTimeSeconds;
    } else {
      // Time elapsed SINCE step started
      newProgress = runSession.elapsedTime.inSeconds.toDouble() - _currentSession!.stepStartTimeSeconds;
      actualDistance = runSession.totalDistance - _currentSession!.stepStartDistance;
      actualTime = newProgress.toInt();
    }

    // Update progress + actual stats
    _currentSession = _currentSession!.copyWith(
      currentStepProgress: newProgress,
      stepActualDistance: actualDistance,
      stepActualTimeSeconds: actualTime,
    );

    // Check for 50% mid-step feedback (only for non-rest steps with target pace)
    final currentStepIndex = _currentSession!.currentStepIndex;
    if (!_midStepFeedbackGiven.contains(currentStepIndex) && 
        !currentStep.isRest && 
        currentStep.targetPace != null) {
      // Calculate progress percentage manually
      final target = currentStep.type == IntervalType.distance 
          ? (currentStep.targetDistance ?? 0) 
          : (currentStep.targetDuration?.inSeconds.toDouble() ?? 0);
      final progressPercentage = target > 0 ? (newProgress / target) * 100 : 0.0;
      
      if (progressPercentage >= 50.0) {
        _midStepFeedbackGiven.add(currentStepIndex);
        _events.add(IntervalMidStepFeedback(currentStep, currentStepIndex));
      }
    }

    // Check if current step is completed
    if (_currentSession!.isCurrentStepCompleted) {
      _handleStepCompletion(runSession);
    }

    return (_currentSession!, List.from(_events));
  }

  void _handleStepCompletion(RunSession runSession) {
    final completedStep = _currentSession!.currentStep!;
    final completedIndex = _currentSession!.currentStepIndex;
    
    _events.add(IntervalStepCompleted(completedStep, completedIndex));

    // Check if all steps are completed
    if (_currentSession!.isAllStepsCompleted) {
      _currentSession = _currentSession!.copyWith(
        status: IntervalSessionStatus.completed,
        endTime: DateTime.now(),
      );
      _events.add(IntervalWorkoutCompleted());
      return;
    }

    // Move to next step
    final nextIndex = _currentSession!.currentStepIndex + 1;
    
    // Reset for new step
    _currentSession = _currentSession!.copyWith(
      currentStepIndex: nextIndex,
      currentStepProgress: 0,
      stepStartDistance: runSession.totalDistance,
      stepStartTimeSeconds: runSession.elapsedTime.inSeconds,
      stepActualDistance: 0, // Reset actual stats
      stepActualTimeSeconds: 0,
    );

    final nextStep = _currentSession!.currentStep;
    if (nextStep != null) {
      _events.add(IntervalStepStarted(nextStep, nextIndex));
    }
  }

  /// Stop current interval session
  IntervalSession? stop() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        status: IntervalSessionStatus.completed,
        endTime: DateTime.now(),
      );
    }
    return _currentSession;
  }

  /// Get current session
  IntervalSession? get currentSession => _currentSession;

  IntervalSession _createEmptySession() {
    // This should never be called, but provides a safe default
    throw StateError('No active interval session');
  }
}
