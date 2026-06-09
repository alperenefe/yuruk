import 'package:flutter/material.dart';

import '../../domain/entities/run_session.dart';
import '../utils/format_utils.dart';
import 'animated_stat_value.dart';

class RunStatsRow extends StatelessWidget {
  const RunStatsRow({super.key, required this.session, this.isRunning = false});

  final RunSession? session;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AnimatedStatValue(
          label: 'Mesafe',
          value: session != null
              ? formatDistance(session!.totalDistance)
              : '0.00 km',
          emphasize: isRunning,
        ),
        AnimatedStatValue(
          label: 'Süre',
          value: session != null
              ? formatDuration(session!.elapsedTime)
              : '0:00',
          emphasize: isRunning,
        ),
        AnimatedStatValue(
          label: 'Pace',
          value: session?.averagePaceFormatted ?? '--:--',
          emphasize: isRunning,
        ),
      ],
    );
  }
}
