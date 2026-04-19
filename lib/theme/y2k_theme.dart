import 'package:flutter/material.dart';

/// Y2K design tokens — Neo-Y2K palette from firstdesign handoff.
class Y2K {
  // Palette
  static const Color bg = Color(0xFFFFF5E1);
  static const Color bgOuter = Color(0xFFE8E2D4);
  static const Color ink = Color(0xFF0E0E12);
  static const Color ink2 = Color(0xFF2A2A33);
  static const Color muted = Color(0xFF7A7A85);
  static const Color card = Colors.white;
  static const Color chip = Color(0xFFEDE4CE);

  static const Color lime = Color(0xFFC6FF3D); // --accent
  static const Color pink = Color(0xFFFF5EA8); // --accent-2
  static const Color blue = Color(0xFF3D6BFF); // --accent-3
  static const Color gold = Color(0xFFFFB800); // --accent-4
  static const Color danger = Color(0xFFFF5E5E);

  // Geometry
  static const double radius = 18;
  static const double radiusSm = 10;
  static const double borderWidth = 2;

  // Hard-edge shadow (Y2K signature — offset, zero blur)
  static List<BoxShadow> shadow({double offset = 4, Color color = ink}) => [
        BoxShadow(color: color, offset: Offset(offset, offset), blurRadius: 0),
      ];

  // Text styles
  static const String _mono = 'monospace';

  static const TextStyle displayLg = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    height: 0.95,
    color: ink,
  );

  static const TextStyle displayMd = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.05,
    color: ink,
  );

  static const TextStyle displaySm = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.1,
    color: ink,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: ink,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: ink2,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: ink,
  );

  static const TextStyle monoSm = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: ink,
  );

  static const TextStyle serifItalic = TextStyle(
    fontFamily: 'serif',
    fontStyle: FontStyle.italic,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: ink,
  );

  static ThemeData theme() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: ink,
      onPrimary: bg,
      secondary: lime,
      onSecondary: ink,
      tertiary: pink,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: bg,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: null, // system default
      textTheme: const TextTheme(
        displayLarge: displayLg,
        displayMedium: displayMd,
        displaySmall: displaySm,
        titleLarge: title,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: bodyMuted,
        labelLarge: TextStyle(fontWeight: FontWeight.w700, color: ink),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.3,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ink, width: borderWidth),
          borderRadius: BorderRadius.circular(radius),
        ),
        titleTextStyle: title,
        contentTextStyle: body,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: bg, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ink, width: borderWidth),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: ink, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: ink, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: pink, width: borderWidth + 0.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: danger, width: borderWidth),
        ),
      ),
      dividerColor: ink,
      cardTheme: const CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
