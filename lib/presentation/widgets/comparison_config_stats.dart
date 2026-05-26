import 'package:flutter/material.dart';
import '../../core/config/gps_filter_params.dart';
import '../../core/filters/gps_filter_pipeline.dart';

/// Bir filtre sonucunun istatistiklerini gösteren mini kart içeriği.
class ResultStatsView extends StatelessWidget {
  final FilteredTrackResult result;
  const ResultStatsView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final smoothness = result.smoothnessScore;
    final (smoothLabel, smoothColor) = _smoothnessLabel(smoothness, context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(Icons.straighten, result.distanceFormatted),
        _Row(Icons.location_on, '${result.acceptedCount} nokta'),
        _Row(Icons.timeline, smoothLabel, color: smoothColor),
        _Row(
          Icons.filter_alt,
          '%${(result.retentionRate * 100).toStringAsFixed(0)} tutuldu',
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  (String, Color) _smoothnessLabel(double score, BuildContext context) {
    if (score < 500) return ('Çok Düzgün', Colors.green.shade700);
    if (score < 1500) return ('Düzgün', Colors.green.shade700);
    if (score < 3000) return ('Orta', Colors.orange.shade700);
    return ('Gürültülü', Colors.red.shade700);
  }
}

/// Preset özet bilgisini (Kalman, hız, doğruluk) gösteren mini kart içeriği.
class ConfigSummaryView extends StatelessWidget {
  final GpsFilterParams config;
  const ConfigSummaryView({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(
          Icons.gps_fixed,
          config.accuracyThreshold >= 9000
              ? 'Doğruluk: ∞'
              : 'Doğruluk ≤${config.accuracyThreshold.round()}m',
        ),
        _Row(
          Icons.speed,
          config.maxSpeedKmh >= 9000
              ? 'Hız: ∞'
              : 'Hız ≤${config.maxSpeedKmh.round()} km/h',
        ),
        _Row(
          config.useKalman ? Icons.waves : Icons.block,
          config.useKalman ? 'Kalman açık' : 'Kalman kapalı',
          color:
              config.useKalman ? Colors.blue.shade700 : Colors.grey.shade500,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Row(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color ?? Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: color ?? Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
