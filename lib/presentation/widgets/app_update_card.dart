import 'package:flutter/material.dart';

import '../../l10n/app_update_strings.dart';
import '../../services/app_distribution_update.dart';

/// Geçmiş ekranı — Firebase App Distribution guncelleme.
class AppUpdateCard extends StatefulWidget {
  const AppUpdateCard({super.key});

  @override
  State<AppUpdateCard> createState() => _AppUpdateCardState();
}

class _AppUpdateCardState extends State<AppUpdateCard> {
  var _busy = false;

  Future<void> _check() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await AppDistributionUpdate.checkFromApp();
    if (!mounted) return;
    setState(() => _busy = false);
    final msg = switch (result) {
      AppUpdateResult.upToDate => AppUpdateStrings.upToDate,
      AppUpdateResult.updateStarted => AppUpdateStrings.started,
      AppUpdateResult.debugBuild => AppUpdateStrings.debugOnly,
      AppUpdateResult.firebaseNotConfigured => AppUpdateStrings.firebaseMissing,
      AppUpdateResult.failed => AppUpdateStrings.failed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppUpdateStrings.section,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppUpdateStrings.hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _check,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update_rounded),
              label: Text(AppUpdateStrings.check),
            ),
          ],
        ),
      ),
    );
  }
}
