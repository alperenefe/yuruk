import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/run_session_provider.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/entities/workout_plan.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/location_access_status.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import '../utils/run_share.dart';
import '../widgets/run_map_widget.dart';
import '../widgets/algorithm_legend_widget.dart';
import '../widgets/run_stats_row.dart';
import '../widgets/run_control_bar.dart';
import '../widgets/location_permission_banner.dart';

class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  TrackPoint? _initialPosition;
  WorkoutPlan? _selectedPlan;
  final WorkoutRepository _workoutRepository = getIt<WorkoutRepository>();
  LocationAccessStatus _locationAccess = LocationAccessStatus.denied;
  bool _locationCheckDone = false;

  @override
  void initState() {
    super.initState();
    _refreshLocationAccess(requestIfNeeded: true);
  }

  Future<void> _refreshLocationAccess({bool requestIfNeeded = false}) async {
    final locationRepo = getIt<LocationRepository>();

    var status = await locationRepo.getAccessStatus();
    if (requestIfNeeded &&
        status == LocationAccessStatus.denied) {
      await locationRepo.requestPermission();
      status = await locationRepo.getAccessStatus();
    }

    if (!mounted) return;
    setState(() {
      _locationAccess = status;
      _locationCheckDone = true;
    });

    if (status != LocationAccessStatus.granted) return;

    try {
      final last = await locationRepo.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() => _initialPosition = last);
      }
    } catch (_) {}

    try {
      final accurate = await locationRepo.getCurrentPosition()
          .timeout(const Duration(minutes: 1));
      if (mounted) {
        setState(() => _initialPosition = accurate);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Could not get accurate position: $e');
    }
  }

  Future<void> _openLocationSettings() async {
    final locationRepo = getIt<LocationRepository>();
    await locationRepo.openAppSettings();
    if (!mounted) return;
    await _refreshLocationAccess(requestIfNeeded: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(runSessionControllerProvider);
    final controller = ref.read(runSessionControllerProvider.notifier);

    // Koşu varsa trackPoint'ten, yoksa initial position'dan al
    final currentPosition = state.currentSession?.trackPoints.isNotEmpty == true
        ? state.currentSession!.trackPoints.last
        : _initialPosition;

    final stoppedWithTrack = !state.isRunning &&
        state.currentSession != null &&
        state.currentSession!.status == RunStatus.stopped &&
        state.currentSession!.trackPoints.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yürük'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          if (stoppedWithTrack)
            IconButton(
              tooltip: 'GPX paylaş',
              icon: const Icon(Icons.share),
              onPressed: () =>
                  RunShare.share(context, state.currentSession!),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_locationCheckDone &&
              _locationAccess != LocationAccessStatus.granted)
            LocationPermissionBanner(
              status: _locationAccess,
              onRetry: () => _refreshLocationAccess(requestIfNeeded: true),
              onOpenSettings: _openLocationSettings,
            ),
          Expanded(
            flex: 2,
            child: RunMapWidget(
              currentPosition: currentPosition,
              routePoints: state.currentSession?.trackPoints ?? [],
              algorithmResults: state.algorithmResults,
            ),
          ),

          if (state.isRunning && state.algorithmResults.isNotEmpty)
            AlgorithmLegendWidget(results: state.algorithmResults),
          
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (state.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Hata: ${state.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    RunStatsRow(session: state.currentSession),
                    
                    if (!state.isRunning) ...[
                      const SizedBox(height: 12),
                      _buildWorkoutPlanSelector(),
                    ],

                    if (stoppedWithTrack) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () =>
                            RunShare.share(context, state.currentSession!),
                        icon: const Icon(Icons.share),
                        label: const Text('GPX paylaş (WhatsApp vb.)'),
                      ),
                    ],

                    const SizedBox(height: 12),
                    RunControlBar(
                      isRunning: state.isRunning,
                      isLoading: state.isLoading,
                      onStart: _locationAccess == LocationAccessStatus.granted
                          ? () => controller.startRun(workoutPlan: _selectedPlan)
                          : () => _refreshLocationAccess(requestIfNeeded: true),
                      onStop: controller.stopRun,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPlanSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: _showPlanSelector,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _selectedPlan != null ? Colors.orange.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedPlan != null ? Colors.orange : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedPlan != null ? Icons.fitness_center : Icons.list,
                color: _selectedPlan != null ? Colors.orange : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedPlan != null ? _selectedPlan!.name : 'Plan Seç',
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedPlan != null ? Colors.orange.shade900 : Colors.grey.shade700,
                  fontWeight: _selectedPlan != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (_selectedPlan != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedPlan = null),
                  child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPlanSelector() async {
    final plans = await _workoutRepository.getAllPlans();
    
    if (!mounted) return;

    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Henüz plan yok. "Etkinlikler" sekmesinden oluştur.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Etkinlik Planı Seç',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return ListTile(
                  leading: const Icon(Icons.fitness_center, color: Colors.orange),
                  title: Text(plan.name),
                  subtitle: Text('${plan.stepCount} adım'),
                  trailing: _selectedPlan?.id == plan.id
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() => _selectedPlan = plan);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
