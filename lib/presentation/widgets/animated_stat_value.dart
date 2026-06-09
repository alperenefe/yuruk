import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Koşu metriklerinde değişimde yumuşak geçiş (NRC / Strava hissi).
class AnimatedStatValue extends StatelessWidget {
  const AnimatedStatValue({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: YurukTokens.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: YurukTokens.durationMedium,
          switchInCurve: YurukTokens.curveStandard,
          switchOutCurve: YurukTokens.curveStandard,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            value,
            key: ValueKey<String>(value),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: emphasize ? 26 : 22,
              color: emphasize ? YurukTokens.runOrange : null,
            ),
          ),
        ),
      ],
    );
  }
}
