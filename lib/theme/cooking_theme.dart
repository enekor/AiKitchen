import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala de espaciado de la app. Un único juego de valores en lugar de
/// paddings inventados pantalla a pantalla.
abstract class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Escala de radios. Tres valores en lugar de los catorce que había.
abstract class AppRadius {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 28;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
}

/// Anchos máximos de contenido.
///
/// Sin un tope, en una ventana de escritorio una línea de texto llega a los
/// 1900 px, unos 200 caracteres. La medida cómoda de lectura está entre 60 y
/// 75 caracteres, así que el texto largo se limita a [readable].
abstract class ContentWidth {
  /// Texto corrido: recetas, pasos, ajustes, formularios.
  static const double readable = 760;

  /// Rejillas y listas, donde varias columnas aprovechan el ancho extra.
  static const double wide = 1200;
}

/// Puntos de corte por ancho de ventana, según Material 3.
///
/// Se mide el ancho y no la orientación: un móvil tumbado y un monitor no son
/// lo mismo, aunque ambos sean "apaisados".
abstract class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1000;

  static bool isCompact(double width) => width < medium;
  static bool isExpanded(double width) => width >= expanded;
}

class CookingTheme {
  static const Color primaryBlue = Color(0xFF005AC1);

  /// Permite construir el tema sin la tipografía de Google.
  ///
  /// Solo se pone a `false` en las pruebas: esa librería descarga la fuente por
  /// red al construir el tema, lo que en un test no funciona y además no tiene
  /// nada que ver con lo que se quiere comprobar, que son tamaños y colores.
  @visibleForTesting
  static bool useGoogleFonts = true;

  static ThemeData lightTheme([ColorScheme? dynamicColorScheme]) =>
      _build(Brightness.light, dynamicColorScheme);

  static ThemeData darkTheme([ColorScheme? dynamicColorScheme]) =>
      _build(Brightness.dark, dynamicColorScheme);

  /// Claro y oscuro comparten construcción para que no se separen con el
  /// tiempo. Antes eran dos copias y ya diferían en detalles como el color
  /// del botón flotante.
  static ThemeData _build(Brightness brightness, ColorScheme? dynamicScheme) {
    final isDark = brightness == Brightness.dark;

    // El esquema dinámico del sistema puede venir con el brillo contrario;
    // en ese caso se descarta para no mezclar un tema claro con colores
    // pensados para fondo oscuro.
    final ColorScheme colorScheme =
        (dynamicScheme != null && dynamicScheme.brightness == brightness)
        ? dynamicScheme
        : ColorScheme.fromSeed(seedColor: primaryBlue, brightness: brightness);

    // El color hay que aplicarlo aquí y no dejarlo para después. Un TextStyle
    // sin color se pinta negro, y estos estilos se reparten tal cual por los
    // subtemas de diálogo, barra y listas: en modo oscuro salía texto negro
    // sobre fondo oscuro, es decir, invisible.
    final textTheme = _textTheme(brightness).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Reduce la altura de filas y controles, pensada para dedo, cuando el
      // dispositivo se maneja con ratón.
      visualDensity: VisualDensity.adaptivePlatformDensity,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          // Un borde sutil define la tarjeta sin depender de una sombra, que
          // en modo oscuro es invisible.
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: Spacing.xl,
        thickness: 1,
      ),

      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        // Un pulgar visible es lo que dice al usuario que se puede arrastrar.
        // Con radio cero el control no se entendía con el ratón.
        thumbColor: colorScheme.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.inverseSurface,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.md,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.4 : 0.6,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        elevation: 1,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 1,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        // Sin tirador automático: las hojas de esta app dibujan el suyo, y
        // activarlo aquí pintaría dos.
        showDragHandle: false,
        backgroundColor: colorScheme.surfaceContainerLow,
        // En apaisado una hoja a todo lo ancho de un monitor es inmanejable.
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
      ),

      tooltipTheme: TooltipThemeData(
        textStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
    );
  }

  /// Escala tipográfica explícita.
  ///
  /// Antes solo se fijaban pesos y se heredaban los tamaños por defecto, así
  /// que no había escalones intermedios entre un título muy grueso y un cuerpo
  /// normal. Aquí se fijan tamaño, peso y espaciado entre letras de cada nivel.
  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    TextStyle style({
      required double size,
      required FontWeight weight,
      double spacing = 0,
      double height = 1.35,
    }) {
      final plain = TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height,
      );
      return useGoogleFonts ? GoogleFonts.robotoFlex(textStyle: plain) : plain;
    }

    final scaled = useGoogleFonts
        ? GoogleFonts.robotoFlexTextTheme(base)
        : base;

    return scaled.copyWith(
      // Títulos: peso alto pero no extremo. El w900 con tracking -2 que había
      // apretaba las letras y se leía peor cuanto más grande era.
      displayLarge: style(size: 44, weight: FontWeight.w700, spacing: -0.5, height: 1.15),
      displayMedium: style(size: 36, weight: FontWeight.w700, spacing: -0.5, height: 1.2),
      displaySmall: style(size: 30, weight: FontWeight.w700, height: 1.2),
      headlineLarge: style(size: 28, weight: FontWeight.w600, height: 1.25),
      headlineMedium: style(size: 24, weight: FontWeight.w600, height: 1.25),
      headlineSmall: style(size: 20, weight: FontWeight.w600, height: 1.3),
      titleLarge: style(size: 20, weight: FontWeight.w600, height: 1.3),
      titleMedium: style(size: 16, weight: FontWeight.w600, spacing: 0.1),
      titleSmall: style(size: 14, weight: FontWeight.w600, spacing: 0.1),

      // Cuerpo: interlineado generoso, que es lo que más ayuda a leer párrafos
      // largos como los pasos de una receta.
      bodyLarge: style(size: 16, weight: FontWeight.w400, height: 1.55),
      bodyMedium: style(size: 14, weight: FontWeight.w400, height: 1.55),
      bodySmall: style(size: 12, weight: FontWeight.w400, height: 1.5),

      // Etiquetas: tracking positivo, que es donde sí hace falta, sobre todo
      // en los rótulos en mayúsculas.
      labelLarge: style(size: 14, weight: FontWeight.w600, spacing: 0.3),
      labelMedium: style(size: 12, weight: FontWeight.w600, spacing: 0.4),
      labelSmall: style(size: 11, weight: FontWeight.w600, spacing: 0.8),
    );
  }
}
