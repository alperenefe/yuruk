import 'package:flutter/material.dart';

import '../../l10n/app_update_strings.dart';

class AppUpdateCard extends StatelessWidget {
  const AppUpdateCard({super.key});

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
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
