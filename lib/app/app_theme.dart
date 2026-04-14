import 'package:flutter/material.dart';

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F5B78),
    brightness: brightness,
  ).copyWith(
    primary: const Color(0xFF0F5B78),
    secondary: const Color(0xFFE57A44),
    surface: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F5EF),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F1E8),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? Colors.white : const Color(0xFF173042),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.white.withOpacity(0.92),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD6E0EA),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFC7D5E3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFC7D5E3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF0F5B78), width: 1.4),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(
        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD6E0EA),
      ),
      selectedColor: const Color(0xFF173042),
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      labelStyle: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF173042),
      ),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
    ),
  );
}
