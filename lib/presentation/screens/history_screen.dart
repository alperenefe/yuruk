import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/run_session.dart';
import '../../domain/repositories/run_session_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final RunSessionRepository _repository = getIt<RunSessionRepository>();
  List<RunSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final sessions = await _repository.getAllSessions();
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _deleteSession(String id) async {
    await _repository.deleteSession(id);
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koşu Geçmişi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_run, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Henüz koşu yok',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'İlk koşunu başlat!',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _sessions.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.directions_run,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          '${(session.totalDistance / 1000).toStringAsFixed(2)} km',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(session.startTime),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(session.elapsedTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.speed, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  session.averagePaceFormatted,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteDialog(session),
                        ),
                        onTap: () {
                          // TODO: Navigate to detail screen
                        },
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    
    if (sessionDay == today) {
      return 'Bugün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (sessionDay == today.subtract(const Duration(days: 1))) {
      return 'Dün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(RunSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Koşuyu Sil'),
        content: Text(
          '${(session.totalDistance / 1000).toStringAsFixed(2)} km koşusunu silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(session.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
