import 'package:flutter/material.dart';

// Палитра приложения.
// Здесь живут базовые AMOLED-поверхности и производные цвета от акцента.
class KeeperPalette {
  const KeeperPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHigher,
    required this.answerBackground,
    required this.answerBorder,
    required this.heroStart,
    required this.outline,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHigher;
  final Color answerBackground;
  final Color answerBorder;
  final Color heroStart;
  final Color outline;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final Color badgeBackground;
  final Color badgeForeground;

  Color get accentSurface => Color.alphaBlend(badgeBackground, surfaceHigh);
}

class KeeperTheme extends ThemeExtension<KeeperTheme> {
  const KeeperTheme({required this.palette});

  final KeeperPalette palette;

  @override
  KeeperTheme copyWith({KeeperPalette? palette}) {
    return KeeperTheme(palette: palette ?? this.palette);
  }

  @override
  KeeperTheme lerp(ThemeExtension<KeeperTheme>? other, double t) {
    if (other is! KeeperTheme) {
      return this;
    }

    final a = palette;
    final b = other.palette;
    return KeeperTheme(
      palette: KeeperPalette(
        background: Color.lerp(a.background, b.background, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        surfaceHigh: Color.lerp(a.surfaceHigh, b.surfaceHigh, t)!,
        surfaceHigher: Color.lerp(a.surfaceHigher, b.surfaceHigher, t)!,
        answerBackground: Color.lerp(a.answerBackground, b.answerBackground, t)!,
        answerBorder: Color.lerp(a.answerBorder, b.answerBorder, t)!,
        heroStart: Color.lerp(a.heroStart, b.heroStart, t)!,
        outline: Color.lerp(a.outline, b.outline, t)!,
        accent: Color.lerp(a.accent, b.accent, t)!,
        textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
        textMuted: Color.lerp(a.textMuted, b.textMuted, t)!,
        badgeBackground: Color.lerp(a.badgeBackground, b.badgeBackground, t)!,
        badgeForeground: Color.lerp(a.badgeForeground, b.badgeForeground, t)!,
      ),
    );
  }
}

// Удобный хелпер для получения нашей расширенной палитры из ThemeData.
KeeperPalette keeperPalette(BuildContext context) {
  return Theme.of(context).extension<KeeperTheme>()!.palette;
}

ThemeData buildKeeperTheme(Color accentColor) {
  // Общая Material 3 тема пересчитывается от акцентного цвета пользователя.
  final palette = _paletteFor(accentColor);
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.accent,
    brightness: Brightness.dark,
    surface: palette.surface,
  ).copyWith(
    primary: palette.accent,
    onPrimary: const Color(0xFF00110E),
    surface: palette.surface,
    surfaceContainer: palette.surface,
    surfaceContainerHigh: palette.surfaceHigh,
    surfaceContainerHighest: palette.surfaceHigher,
    secondaryContainer: palette.badgeBackground,
    onSecondaryContainer: palette.badgeForeground,
    onSurface: palette.textPrimary,
    onSurfaceVariant: palette.textMuted,
    outline: palette.outline,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    extensions: [
      KeeperTheme(palette: palette),
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: palette.textPrimary,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      toolbarHeight: 54,
      titleTextStyle: TextStyle(
        color: palette.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: palette.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: palette.textMuted,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      margin: EdgeInsets.zero,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: palette.textPrimary,
        backgroundColor: palette.surfaceHigh.withValues(alpha: 0.5),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceHigh.withValues(alpha: 0.75),
      hintStyle: TextStyle(
        color: palette.textMuted.withValues(alpha: 0.82),
      ),
      labelStyle: TextStyle(color: palette.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: palette.outline),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: palette.badgeBackground,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? palette.textPrimary : palette.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? palette.badgeForeground : palette.textMuted,
        );
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.accent,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceHigher,
      contentTextStyle: TextStyle(color: palette.textPrimary),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}

KeeperPalette _paletteFor(Color accentColor) {
  // База взята как AMOLED-палитра, а потом мягко тонируется выбранным акцентом.
  const base = KeeperPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF070A0A),
    surfaceHigh: Color(0xFF0B1010),
    surfaceHigher: Color(0xFF111818),
    answerBackground: Color(0xFF0C1111),
    answerBorder: Color(0xFF12302E),
    heroStart: Color(0xFF0E1414),
    outline: Color(0xFF12302E),
    accent: Color(0xFF2DD4BF),
    textPrimary: Color(0xFFF5F3FF),
    textMuted: Color(0xFF8C97A3),
    badgeBackground: Color(0x332DD4BF),
    badgeForeground: Color(0xFF99F6E4),
  );

  return KeeperPalette(
    background: base.background,
    surface: Color.lerp(base.surface, accentColor, 0.02)!,
    surfaceHigh: Color.lerp(base.surfaceHigh, accentColor, 0.02)!,
    surfaceHigher: Color.lerp(base.surfaceHigher, accentColor, 0.02)!,
    answerBackground: Color.lerp(base.answerBackground, accentColor, 0.02)!,
    answerBorder: Color.lerp(base.answerBorder, accentColor, 0.06)!,
    heroStart: Color.lerp(base.heroStart, accentColor, 0.08)!,
    outline: Color.lerp(base.outline, accentColor, 0.06)!,
    accent: accentColor,
    textPrimary: base.textPrimary,
    textMuted: base.textMuted,
    badgeBackground: accentColor.withValues(alpha: 0.2),
    badgeForeground: accentColor,
  );
}
