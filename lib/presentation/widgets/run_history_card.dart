import 'package:flutter/material.dart';

import '../../domain/entities/run_session.dart';
import '../theme/design_tokens.dart';
import '../utils/format_utils.dart';
import '../utils/run_share.dart';
import 'activity_list_card.dart';

class RunHistoryCard extends StatelessWidget {
  const RunHistoryCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final RunSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasPoints = session.labInputPoints.isNotEmpty;
    final theme = Theme.of(context);
    return ActivityListCard(
      icon: Icons.directions_run_rounded,
      iconColor: YurukTokens.primary,
      iconBackground: YurukTokens.primary.withValues(alpha: 0.12),
      title: formatDistance(session.totalDistance),
      enabled: hasPoints,
      onTap: hasPoints ? onTap : null,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(session.startTime),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: YurukTokens.textSecondary),
              const SizedBox(width: 4),
              Text(
                formatDuration(session.elapsedTime),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: 14),
              Icon(Icons.speed_rounded, size: 14, color: YurukTokens.textSecondary),
              const SizedBox(width: 4),
              Text(
                session.averagePaceFormatted,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'GPX paylaş',
            icon: const Icon(Icons.ios_share_rounded),
            color: YurukTokens.primary,
            onPressed: () => RunShare.share(context, session),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: YurukTokens.danger,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (sessionDay == today) return 'Bugün $time';
    if (sessionDay == today.subtract(const Duration(days: 1))) {
      return 'Dün $time';
    }
    return '${date.day}.${date.month}.${date.year} $time';
  }
}
