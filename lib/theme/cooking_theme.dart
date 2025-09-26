import 'package:flutter/material.dart';

class CookingTheme {
  // Colores principales inspirados en cocina profesional
  static const Color primaryBlue = Color(0xFF2B6CB0); // Azul acero profesional
  static const Color primaryGreen = Color(0xFF38A169); // Verde hierbas
  static const Color primaryRed = Color(0xFFE53E3E); // Rojo fuego

  // Colores secundarios y acentos
  static const Color stainlessSteel = Color(0xFFE2E8F0); // Acero inoxidable
  static const Color darkSteel = Color(0xFF4A5568); // Acero oscuro
  static const Color warmWood = Color(0xFFF6E05E); // Madera cálida
  static const Color ceramicGray = Color(0xFFEDF2F7); // Cerámica
  static const Color spiceRed = Color(0xFFF56565); // Especias
  static const Color herbGreen = Color(0xFF48BB78); // Hierbas frescas

  // Colores neutros
  static const Color cream = Color(0xFFFFFAF0); // Crema suave
  static const Color charcoal = Color(0xFF2D3748); // Carbón
  static const Color slate = Color(0xFF718096); // Pizarra

  // Colores adicionales para la interfaz
  static const Color lightYellow = Color(0xFFFFF3E0); // Amarillo suave
  static const Color brown = Color(0xFF795548); // Marrón cocina
  static const Color darkYellow = Color(0xFFFFC107); // Amarillo oscuro
  static const Color darkGreen = Color(0xFF2E7D32); // Verde oscuro
  static const Color lightGreen = Color(0xFF81C784); // Verde claro
  static const Color darkRed = Color(0xFFC62828); // Rojo oscuro
  static const Color lightRed = Color(0xFFEF5350); // Rojo claro

  static ThemeData lightTheme([ColorScheme? dynamicColorScheme]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Esquema de colores híbrido: dinámicos + temáticos
      colorScheme: ColorScheme.light(
        // Colores temáticos inspirados en cocina profesional
        primary: primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: stainlessSteel,
        onPrimaryContainer: charcoal,

        secondary: primaryGreen,
        onSecondary: Colors.white,
        secondaryContainer: herbGreen,
        onSecondaryContainer: Colors.white,

        tertiary: spiceRed,
        onTertiary: Colors.white,
        tertiaryContainer: primaryRed,
        onTertiaryContainer: Colors.white,

        // Superficies y fondos inspirados en materiales de cocina
        surface: dynamicColorScheme?.surface ?? ceramicGray,
        onSurface: dynamicColorScheme?.onSurface ?? charcoal,
        surfaceContainerHighest:
            dynamicColorScheme?.surfaceContainerHighest ?? stainlessSteel,
        onSurfaceVariant: dynamicColorScheme?.onSurfaceVariant ?? slate,
        surfaceContainer: dynamicColorScheme?.surfaceContainer ?? ceramicGray,
        surfaceContainerHigh:
            dynamicColorScheme?.surfaceContainerHigh ?? stainlessSteel,
        surfaceContainerLow: dynamicColorScheme?.surfaceContainerLow ?? cream,
        surfaceTint: dynamicColorScheme?.surfaceTint ?? primaryBlue,

        // Elementos neutros inspirados en materiales de cocina
        outline: dynamicColorScheme?.outline ?? slate,
        outlineVariant:
            dynamicColorScheme?.outlineVariant ?? darkSteel.withOpacity(0.5),
        inverseSurface: dynamicColorScheme?.inverseSurface ?? charcoal,
        onInverseSurface: dynamicColorScheme?.onInverseSurface ?? Colors.white,

        error: primaryRed,
        onError: Colors.white,
        shadow: Colors.black12,
      ),

      // AppBar con estilo profesional de cocina
      appBarTheme: AppBarTheme(
        backgroundColor: stainlessSteel,
        foregroundColor: charcoal,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: charcoal),
        shadowColor: Colors.black12,
      ),

      // Botones elevados con estilo profesional
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          shadowColor: Colors.black12,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Botones de texto con estilo elegante
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 6,
      ), // Cards
      cardTheme: CardThemeData(
        color: cream,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        fillColor: lightYellow,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brown.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: brown),
        hintStyle: TextStyle(color: brown.withOpacity(0.6)),
      ),

      // Iconos
      iconTheme: const IconThemeData(color: brown, size: 24),

      // Navigation bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cream,
        selectedItemColor: primaryGreen,
        unselectedItemColor: brown,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Texto
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.black87,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.black87,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ), // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return null;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return brown;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return brown.withOpacity(0.3);
        }),
      ),
    );
  }

  static ThemeData darkTheme([ColorScheme? dynamicColorScheme]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Esquema de colores oscuro híbrido: dinámicos + temáticos
      colorScheme: ColorScheme.dark(
        // Colores temáticos fijos para la identidad de la app
        primary: darkYellow,
        onPrimary: Colors.black,
        primaryContainer: const Color(0xFF4A3800),
        onPrimaryContainer: darkYellow,

        secondary: darkGreen,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF1B4A1E),
        onSecondaryContainer: lightGreen,

        tertiary: darkRed,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFF4A1C1C),
        onTertiaryContainer: lightRed,

        // Usar colores dinámicos para surfaces y backgrounds
        surface: dynamicColorScheme?.surface ?? const Color(0xFF1C1B1F),
        onSurface: dynamicColorScheme?.onSurface ?? Colors.white,
        surfaceContainerHighest:
            dynamicColorScheme?.surfaceContainerHighest ??
            const Color(0xFF2A2A2A),
        onSurfaceVariant:
            dynamicColorScheme?.onSurfaceVariant ?? Colors.white70,
        surfaceContainer:
            dynamicColorScheme?.surfaceContainer ?? const Color(0xFF1C1B1F),
        surfaceContainerHigh:
            dynamicColorScheme?.surfaceContainerHigh ?? const Color(0xFF2A2A2A),
        surfaceContainerLow:
            dynamicColorScheme?.surfaceContainerLow ?? const Color(0xFF1C1B1F),
        surfaceTint: dynamicColorScheme?.surfaceTint ?? darkYellow,

        // Usar colores dinámicos para elementos neutros
        outline: dynamicColorScheme?.outline ?? const Color(0xFF938F99),
        outlineVariant:
            dynamicColorScheme?.outlineVariant ??
            const Color(0xFF938F99).withOpacity(0.5),
        inverseSurface: dynamicColorScheme?.inverseSurface ?? Colors.white,
        onInverseSurface: dynamicColorScheme?.onInverseSurface ?? Colors.black,

        error: lightRed,
        onError: Colors.black,
        shadow: Colors.black54,
      ),

      // AppBar oscuro
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1B1F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Botones oscuros
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightRed,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkRed,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2A2A),
        elevation: 4,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF2A2A2A),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),

      iconTheme: const IconThemeData(color: Colors.white70, size: 24),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1B1F),
        selectedItemColor: darkGreen,
        unselectedItemColor: Colors.white54,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
