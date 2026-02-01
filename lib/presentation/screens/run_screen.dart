import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/run_session_provider.dart';

class RunScreen extends ConsumerWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(runSessionControllerProvider);
    final controller = ref.read(runSessionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yürük - Running Tracker'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Error: ${state.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      state.isRunning ? 'KOŞU DEVAM EDİYOR' : 'HAZIR',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: state.isRunning ? Colors.green : Colors.grey,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    if (state.currentSession != null) ...[
                      _buildStatRow(
                        'Mesafe',
                        '${(state.currentSession!.totalDistance / 1000).toStringAsFixed(2)} km',
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Süre',
                        _formatDuration(state.currentSession!.elapsedTime),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Ortalama Pace',
                        state.currentSession!.averagePaceFormatted,
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'GPS Noktaları',
                        '${state.currentSession!.trackPoints.length}',
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: state.isRunning
                      ? () => controller.stopRun()
                      : () => controller.startRun(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isRunning ? Colors.red : Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    state.isRunning ? 'DURDUR' : 'BAŞLAT',
                    style: const TextStyle(
                      fontSize: 20,
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
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
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
