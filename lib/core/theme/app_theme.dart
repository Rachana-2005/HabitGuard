import 'package:flutter/material.dart';

/// Custom Risk Color Palette for HabitGuard
class RiskColors {
  // Low Risk (0 - 30): Emerald / Mint
  static const Color low = Color(0xFF10B981);
  static const Color lowLight = Color(0xFFD1FAE5);
  static const Color lowDark = Color(0xFF047857);

  // Moderate Risk (31 - 60): Amber / Warm Gold
  static const Color moderate = Color(0xFFF59E0B);
  static const Color moderateLight = Color(0xFFFEF3C7);
  static const Color moderateDark = Color(0xFFB45309);

  // High Risk (61 - 80): Vivid Orange
  static const Color high = Color(0xFFF97316);
  static const Color highLight = Color(0xFFFFEDD5);
  static const Color highDark = Color(0xFFC2410C);

  // Critical Risk (81 - 100): Crimson Red
  static const Color critical = Color(0xFFEF4444);
  static const Color criticalLight = Color(0xFFFEE2E2);
  static const Color criticalDark = Color(0xFFB91C1C);

  // Helper method to retrieve color by score
  static Color getColorForScore(int score) {
    if (score <= 30) return low;
    if (score <= 60) return moderate;
    if (score <= 80) return high;
    return critical;
  }

  // Helper method to retrieve light background color by score
  static Color getLightColorForScore(int score) {
    if (score <= 30) return lowLight;
    if (score <= 60) return moderateLight;
    if (score <= 80) return highLight;
    return criticalLight;
  }
}

/// Category Accent Colors
class CategoryColors {
  static const Color socialMedia = Color(0xFFEC4899);    // Pink
  static const Color gaming = Color(0xFF8B5CF6);         // Purple
  static const Color entertainment = Color(0xFF3B82F6);  // Blue
  static const Color education = Color(0xFF10B981);      // Emerald
  static const Color productivity = Color(0xFF06B6D4);   // Cyan
  static const Color communication = Color(0xFF14B8A6);  // Teal
  static const Color shopping = Color(0xFFF97316);       // Orange
  static const Color other = Color(0xFF6B7280);          // Gray
}

/// Material 3 Themes for HabitGuard
class AppTheme {
  static const Color primarySeed = Color(0xFF4F46E5); // Indigo 600

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF1F5F9),
      surfaceContainer: const Color(0xFFE2E8F0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: primarySeed.withAlpha(35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primarySeed,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey.shade600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blueGrey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primarySeed, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RiskColors.critical, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      surface: const Color(0xFF0F172A),
      surfaceContainerLowest: const Color(0xFF020617),
      surfaceContainerLow: const Color(0xFF1E293B),
      surfaceContainer: const Color(0xFF334155),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(60),
          ),
        ),
        color: const Color(0xFF1E293B),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        height: 70,
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: primarySeed.withAlpha(80),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF818CF8),
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey.shade400,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blueGrey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RiskColors.critical, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
