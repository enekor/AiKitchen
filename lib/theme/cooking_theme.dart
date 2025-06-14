import 'package:flutter/material.dart';

class CookingTheme {
  // Colores principales inspirados en la hamburguesa
  static const Color primaryYellow = Color(0xFFFFB74D); // Amarillo dorado (pan)
  static const Color primaryGreen = Color(0xFF66BB6A); // Verde fresco (lechuga)
  static const Color primaryRed = Color(0xFFE57373); // Rojo tomate

  // Colores secundarios
  static const Color lightYellow = Color(0xFFFFF8DC); // Beige claro
  static const Color darkYellow = Color(0xFFFF8F00); // Amarillo oscuro
  static const Color lightGreen = Color(0xFFC8E6C9); // Verde claro
  static const Color darkGreen = Color(0xFF388E3C); // Verde oscuro
  static const Color lightRed = Color(0xFFFFCDD2); // Rosa claro
  static const Color darkRed = Color(0xFFD32F2F); // Rojo oscuro

  // Colores neutros
  static const Color cream = Color(0xFFFAF7F2); // Crema
  static const Color brown = Color(0xFF8D6E63); // Marrón
  static const Color darkBrown = Color(0xFF5D4037); // Marrón oscuro

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Esquema de colores
      colorScheme: const ColorScheme.light(
        primary: primaryYellow,
        onPrimary: Colors.black87,
        primaryContainer: lightYellow,
        onPrimaryContainer: Colors.black87,

        secondary: primaryGreen,
        onSecondary: Colors.white,
        secondaryContainer: lightGreen,
        onSecondaryContainer: Colors.black87,

        tertiary: primaryRed,
        onTertiary: Colors.white,
        tertiaryContainer: lightRed,
        onTertiaryContainer: Colors.black87,
        surface: cream,
        onSurface: Colors.black87,
        surfaceContainerHighest: lightYellow,
        onSurfaceVariant: Colors.black87,

        error: darkRed,
        onError: Colors.white,

        outline: brown,
        shadow: Colors.black26,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryYellow,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRed,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return brown;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return brown.withOpacity(0.3);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Esquema de colores oscuro
      colorScheme: const ColorScheme.dark(
        primary: darkYellow,
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF4A3800),
        onPrimaryContainer: darkYellow,

        secondary: darkGreen,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF1B4A1E),
        onSecondaryContainer: lightGreen,

        tertiary: darkRed,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF4A1C1C),
        onTertiaryContainer: lightRed,
        surface: Color(0xFF1C1B1F),
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF2A2A2A),
        onSurfaceVariant: Colors.white70,

        error: lightRed,
        onError: Colors.black,

        outline: Color(0xFF938F99),
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
