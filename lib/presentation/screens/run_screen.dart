import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/run_session_provider.dart';
import '../../domain/entities/track_point.dart';
import '../../core/di/service_locator.dart';
import '../../domain/repositories/location_repository.dart';
import '../widgets/run_map_widget.dart';

class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  TrackPoint? _initialPosition;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosition();
  }

  Future<void> _fetchInitialPosition() async {
    try {
      final locationRepo = getIt<LocationRepository>();
      final position = await locationRepo.getCurrentPosition();
      if (mounted) {
        setState(() {
          _initialPosition = position;
        });
      }
    } catch (e) {
      print('⚠️ Could not get initial position: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(runSessionControllerProvider);
    final controller = ref.read(runSessionControllerProvider.notifier);

    // Koşu varsa trackPoint'ten, yoksa initial position'dan al
    final currentPosition = state.currentSession?.trackPoints.isNotEmpty == true
        ? state.currentSession!.trackPoints.last
        : _initialPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yürük'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: RunMapWidget(
              currentPosition: currentPosition,
              routePoints: state.currentSession?.trackPoints ?? [],
            ),
          ),
          
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state.error != null)
                    Container(
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
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCompactStat(
                        'Mesafe',
                        state.currentSession != null
                            ? '${(state.currentSession!.totalDistance / 1000).toStringAsFixed(2)} km'
                            : '0.00 km',
                      ),
                      _buildCompactStat(
                        'Süre',
                        state.currentSession != null
                            ? _formatDuration(state.currentSession!.elapsedTime)
                            : '0:00',
                      ),
                      _buildCompactStat(
                        'Pace',
                        state.currentSession != null
                            ? state.currentSession!.averagePaceFormatted
                            : '--:--',
                      ),
                    ],
                  ),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : (state.isRunning
                              ? () => controller.stopRun()
                              : () => controller.startRun()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isRunning ? Colors.red : Colors.green,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              state.isRunning ? 'DURDUR' : 'BAŞLAT',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
