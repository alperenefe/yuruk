import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/run_session.dart';
import '../../infrastructure/export/gpx_exporter.dart';

class RunShare {
  static Future<void> share(BuildContext context, RunSession session) async {
    try {
      final text = _summary(session);
      if (!session.hasGpxGeometry) {
        await SharePlus.instance.share(
          ShareParams(text: text, subject: 'Yürük'),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final safeId = session.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      final fileName = 'yuruk_$safeId.gpx';
      final path = '${dir.path}/$fileName';
      final file = File(path);
      await file.writeAsString(GpxExporter.toGpx(session));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/gpx+xml', name: fileName)],
          text: text,
          subject: 'Yürük koşusu',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paylaşım başarısız: $e')),
        );
      }
    }
  }

  static String _summary(RunSession s) {
    final km = (s.totalDistance / 1000).toStringAsFixed(2);
    final d = s.elapsedTime;
    final dur = d.inHours > 0
        ? '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}'
        : '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return 'Yürük — $km km · $dur · ${s.averagePaceFormatted}';
  }
}
