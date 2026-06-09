import 'package:flutter/material.dart';

abstract final class YurukTokens {
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF3B82F6);
  static const surface = Color(0xFFF8FAFC);
  static const surfaceDark = Color(0xFF0F172A);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1E293B);
  static const border = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF334155);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textOnDark = Color(0xFFF1F5F9);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const runOrange = Color(0xFFEA580C);

  static const radiusMd = 14.0;
  static const radiusLg = 18.0;

  static const durationFast = Duration(milliseconds: 200);
  static const durationMedium = Duration(milliseconds: 320);
  static const curveStandard = Curves.easeOutCubic;

  static List<BoxShadow> cardShadow(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
