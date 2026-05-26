import 'package:flutter/material.dart';
import '../../domain/entities/run_session.dart';
import '../utils/format_utils.dart';

/// Geçmişten bir koşu seçmek için modal bottom sheet.
/// Hem Comparison Lab hem de başka ekranlarda kullanılabilir.
class RunPickerSheet extends StatelessWidget {
  final List<RunSession> sessions;

  const RunPickerSheet({super.key, required this.sessions});

  /// [sessions] listesini gösterir; kullanıcı seçim yaparsa `RunSession`
  /// döndürür, iptalde `null` döndürür.
  static Future<RunSession?> show(
    BuildContext context,
    List<RunSession> sessions,
  ) {
    return showModalBottomSheet<RunSession>(
      context: context,
      builder: (_) => RunPickerSheet(sessions: sessions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Koşu Seç',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (ctx, i) {
                final s = sessions[i];
                final date =
                    '${s.startTime.day}.${s.startTime.month}.${s.startTime.year}';
                final pts = s.labInputPoints.length;
                return ListTile(
                  leading:
                      const Icon(Icons.directions_run, color: Colors.blue),
                  title: Text('$date — ${formatDistance(s.totalDistance)}'),
                  subtitle: Text('$pts nokta'),
                  enabled: pts > 0,
                  onTap: pts > 0 ? () => Navigator.pop(context, s) : null,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
