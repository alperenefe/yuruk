import 'package:flutter/material.dart';
import '../../core/filters/gps_filter_pipeline.dart';

class AlgorithmLegendWidget extends StatelessWidget {
  final List<FilteredTrackResult> results;

  const AlgorithmLegendWidget({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: results.map((r) => _AlgorithmChip(result: r)).toList(),
      ),
    );
  }
}

class _AlgorithmChip extends StatelessWidget {
  final FilteredTrackResult result;

  const _AlgorithmChip({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: result.params.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              result.params.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          result.distanceFormatted,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: result.params.color,
          ),
        ),
      ],
    );
  }
}
