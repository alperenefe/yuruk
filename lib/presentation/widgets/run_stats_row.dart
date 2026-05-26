import 'package:flutter/material.dart';
import '../../domain/entities/run_session.dart';
import '../utils/format_utils.dart';

/// Aktif koşu sırasında mesafe / süre / pace'i gösteren istatistik satırı.
class RunStatsRow extends StatelessWidget {
  final RunSession? session;
  const RunStatsRow({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(
          label: 'Mesafe',
          value: session != null
              ? formatDistance(session!.totalDistance)
              : '0.00 km',
        ),
        _Stat(
          label: 'Süre',
          value: session != null
              ? formatDuration(session!.elapsedTime)
              : '0:00',
        ),
        _Stat(
          label: 'Pace',
          value: session?.averagePaceFormatted ?? '--:--',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
