import 'package:flutter/material.dart';

/// Brand colors from the Stipa Figma mockup. They are the same in both
/// themes; the neutral colors live in [AppPalette].
class AppColors {
  static const accent = Color(0xFFA4C639);
  static const accentDark = Color(0xFF8DAA2E);
  static const accentSoft = Color(0x26A4C639);
  static const danger = Color(0xFFC4532F);
  static const dangerSoft = Color(0x26C4532F);
}

/// Neutral colors that change with the LW11 dark mode switch.
///
/// Read them with `context.palette.card`, so a widget repaints when the
/// theme changes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color card;
  final Color cardLight;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Lime for text and icons. On a light background the bright lime is
  /// unreadable, so the light palette uses a darker shade.
  final Color accentText;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.cardLight,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentText,
  });

  /// The Figma mockup.
  static const dark = AppPalette(
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF161616),
    card: Color(0xFF1E1E1E),
    cardLight: Color(0xFF262626),
    border: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFF2F2F2),
    textSecondary: Color(0xFF9A9A9A),
    textMuted: Color(0xFF5E5E5E),
    accentText: AppColors.accent,
  );

  static const light = AppPalette(
    background: Color(0xFFF4F5F0),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardLight: Color(0xFFE9EBE3),
    border: Color(0xFFE2E4DC),
    textPrimary: Color(0xFF151515),
    textSecondary: Color(0xFF6B6B6B),
    textMuted: Color(0xFFA3A3A3),
    accentText: Color(0xFF5A7512),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? cardLight,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accentText,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardLight: cardLight ?? this.cardLight,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accentText: accentText ?? this.accentText,
    );
  }

  /// Lets MaterialApp animate between the two palettes.
  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardLight: Color.lerp(cardLight, other.cardLight, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppTheme {
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  /// One builder for both themes, so they only differ in the palette.
  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark
        ? const ColorScheme.dark()
        : const ColorScheme.light();

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(
        primary: isDark ? AppColors.accent : AppColors.accentDark,
        onPrimary: Colors.black,
        secondary: AppColors.accent,
        surface: p.background,
        onSurface: p.textPrimary,
        onSurfaceVariant: p.textSecondary,
        surfaceContainerHighest: p.card,
        outline: p.textMuted,
        outlineVariant: p.border,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: p.background,
      extensions: [p],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          // White cards on a light background need an outline.
          side: isDark ? BorderSide.none : BorderSide(color: p.border),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.accentText,
        unselectedItemColor: p.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: p.cardLight,
          disabledForegroundColor: p.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accentText),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        subtitleTextStyle: TextStyle(fontSize: 12, color: p.textSecondary),
      ),
      // The snackbar stays dark in both themes, so the lime action reads.
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF262626),
        contentTextStyle: TextStyle(color: Color(0xFFF2F2F2)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.black : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accent : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accent : null,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.black),
      ),
    );
  }
}
