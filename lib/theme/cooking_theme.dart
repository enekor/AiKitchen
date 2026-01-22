import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CookingTheme {
  // Colores base dinámicos y audaces
  static const Color primaryBlue = Color(0xFF005AC1);
  static const Color primaryGreen = Color(0xFF006D39);
  static const Color secondaryPurple = Color(0xFF6750A4);

  static ThemeData lightTheme([ColorScheme? dynamicColorScheme]) {
    final colorScheme = dynamicColorScheme ?? ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.robotoFlexTextTheme().copyWith(
        displayLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w900, letterSpacing: -2),
        displayMedium: GoogleFonts.robotoFlex(fontWeight: FontWeight.w900, letterSpacing: -1.5),
        displaySmall: GoogleFonts.robotoFlex(fontWeight: FontWeight.w900, letterSpacing: -1),
        headlineLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w700),
      ),
      
      // Sliders estilo M3 Expressive (Barra gruesa)
      sliderTheme: SliderThemeData(
        trackHeight: 20,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primaryContainer,
        thumbColor: colorScheme.onPrimary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Integrado
        trackShape: const RoundedRectSliderTrackShape(),
      ),

      // Botones con formas audaces
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    );
  }

  static ThemeData darkTheme([ColorScheme? dynamicColorScheme]) {
    final colorScheme = dynamicColorScheme ?? ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.robotoFlexTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w900, letterSpacing: -2),
        displayMedium: GoogleFonts.robotoFlex(fontWeight: FontWeight.w900, letterSpacing: -1.5),
        displaySmall: GoogleFonts.robotoFlex(fontWeight: FontWeight.w900, letterSpacing: -1),
        headlineLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.robotoFlex(fontWeight: FontWeight.w700),
      ),
      
      sliderTheme: SliderThemeData(
        trackHeight: 20,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primaryContainer,
        thumbColor: colorScheme.onPrimary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
        trackShape: const RoundedRectSliderTrackShape(),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
    );
  }
}
