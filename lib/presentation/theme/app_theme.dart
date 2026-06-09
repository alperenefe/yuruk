import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

final class YurukAppTheme {
  YurukAppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
            primary: YurukTokens.primaryLight,
            surface: YurukTokens.surfaceDark,
            onSurface: YurukTokens.textOnDark,
          )
        : ColorScheme.fromSeed(
            seedColor: YurukTokens.primary,
            brightness: Brightness.light,
            surface: YurukTokens.surface,
          );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? YurukTokens.surfaceDark : YurukTokens.surface,
    );
    final text = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? YurukTokens.cardDark : YurukTokens.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? YurukTokens.cardDark : YurukTokens.cardLight,
        indicatorColor: YurukTokens.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? YurukTokens.primary
                : (dark ? YurukTokens.textSecondary : YurukTokens.textSecondary),
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: dark ? YurukTokens.cardDark : YurukTokens.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(YurukTokens.radiusLg),
          side: BorderSide(
            color: dark ? YurukTokens.borderDark : YurukTokens.border,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: YurukTokens.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(YurukTokens.radiusMd),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }
}
