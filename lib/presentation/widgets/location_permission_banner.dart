import 'package:flutter/material.dart';
import '../../domain/entities/location_access_status.dart';

/// Konum izni / servis kapalı durumunda Koş ekranında gösterilir.
class LocationPermissionBanner extends StatelessWidget {
  final LocationAccessStatus status;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const LocationPermissionBanner({
    super.key,
    required this.status,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final (title, body, showSettings) = switch (status) {
      LocationAccessStatus.serviceDisabled => (
          'Konum servisi kapalı',
          'GPS ile koşu takibi için cihaz ayarlarından konumu aç.',
          true,
        ),
      LocationAccessStatus.deniedForever => (
          'Konum izni verilmedi',
          'Harita ve koşu için uygulama ayarlarından konum iznini aç.',
          true,
        ),
      LocationAccessStatus.denied => (
          'Konum izni gerekli',
          'Koşuya başlamak için konum iznine izin ver.',
          false,
        ),
      LocationAccessStatus.granted => ('', '', false),
    };

    if (status == LocationAccessStatus.granted) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_off, color: Colors.amber.shade900, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (showSettings)
              TextButton(
                onPressed: onOpenSettings,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ayarlar', style: TextStyle(fontSize: 12)),
              )
            else
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('İzin ver', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
