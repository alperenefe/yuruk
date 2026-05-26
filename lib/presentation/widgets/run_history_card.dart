import 'package:flutter/material.dart';
import '../../domain/entities/run_session.dart';
import '../utils/format_utils.dart';
import '../utils/run_share.dart';

/// Geçmiş listesinde her koşuyu gösteren kart.
class RunHistoryCard extends StatelessWidget {
  final RunSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RunHistoryCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoints = session.labInputPoints.isNotEmpty;
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
          child: const Icon(Icons.directions_run, color: Colors.blue, size: 28),
        ),
        title: Text(
          formatDistance(session.totalDistance),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: _Subtitle(session: session),
        trailing: _Actions(session: session, onDelete: onDelete),
        enabled: hasPoints,
        onTap: hasPoints ? onTap : null,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final RunSession session;
  const _Subtitle({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(_formatDate(session.startTime),
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              formatDuration(session.elapsedTime),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 16),
            Icon(Icons.speed, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              session.averagePaceFormatted,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (sessionDay == today) return 'Bugün $time';
    if (sessionDay == today.subtract(const Duration(days: 1))) return 'Dün $time';
    return '${date.day}.${date.month}.${date.year} $time';
  }
}

class _Actions extends StatelessWidget {
  final RunSession session;
  final VoidCallback onDelete;
  const _Actions({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'GPX paylaş',
          icon: const Icon(Icons.share, color: Colors.blue),
          onPressed: () => RunShare.share(context, session),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
