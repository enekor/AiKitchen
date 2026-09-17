import 'package:flutter/material.dart';

/// Escala de espaciado de la app, en múltiplos de 4.
abstract class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Escala de radios del sistema de diseño.
abstract class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double full = 9999;

  static BorderRadius get extraSmall => BorderRadius.circular(xs);
  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get capsule => BorderRadius.circular(full);
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
  static const double railExtended = 1240;

  static bool isCompact(double width) => width < medium;
  static bool isExpanded(double width) => width >= expanded;
}

/// Acento reservado exclusivamente para flujos de generación por IA: el botón
/// de modificar receta, generar menú, generar lista y las insignias de
/// "generado con IA". No forma parte del [ColorScheme] porque Material no
/// tiene un rol semántico para "esto lo hace la IA".
@immutable
class AiAccent extends ThemeExtension<AiAccent> {
  const AiAccent({
    required this.color,
    required this.container,
    required this.onContainer,
  });

  final Color color;
  final Color container;
  final Color onContainer;

  static const light = AiAccent(
    color: Color(0xFF6366F1),
    container: Color(0xFFEEF2FF),
    onContainer: Color(0xFF6366F1),
  );

  static const dark = AiAccent(
    color: Color(0xFF38BDF8),
    container: Color(0xFF1E1B4B),
    onContainer: Color(0xFF38BDF8),
  );

  @override
  AiAccent copyWith({Color? color, Color? container, Color? onContainer}) {
    return AiAccent(
      color: color ?? this.color,
      container: container ?? this.container,
      onContainer: onContainer ?? this.onContainer,
    );
  }

  @override
  AiAccent lerp(ThemeExtension<AiAccent>? other, double t) {
    if (other is! AiAccent) return this;
    return AiAccent(
      color: Color.lerp(color, other.color, t)!,
      container: Color.lerp(container, other.container, t)!,
      onContainer: Color.lerp(onContainer, other.onContainer, t)!,
    );
  }
}

extension AiAccentContext on BuildContext {
  /// Acceso corto al acento de IA del tema actual.
  AiAccent get aiAccent => Theme.of(this).extension<AiAccent>()!;
}

class CookingTheme {
  static ThemeData lightTheme() => _build(Brightness.light);

  static ThemeData darkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark ? _darkScheme : _lightScheme;
    final aiAccent = isDark ? AiAccent.dark : AiAccent.light;

    final textTheme = _textTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [aiAccent],

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
        color: colorScheme.surfaceContainerLowest,
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.capsule),
        side: BorderSide(color: colorScheme.outlineVariant),
        backgroundColor: Colors.transparent,
        selectedColor: colorScheme.primary,
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        // Un pulgar visible es lo que dice al usuario que se puede arrastrar.
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
          minimumSize: const Size.fromHeight(44),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
          side: BorderSide(color: colorScheme.primary),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
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
        selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
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
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
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
        backgroundColor: colorScheme.surfaceContainerLowest,
        // En apaisado una hoja a todo lo ancho de un monitor es inmanejable.
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0059AC),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF1972D2),
    onPrimaryContainer: Color(0xFFF8F8FF),
    secondary: Color(0xFF4648D4),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF6063EE),
    onSecondaryContainer: Color(0xFFFFFBFF),
    tertiary: Color(0xFF006184),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF007BA6),
    onTertiaryContainer: Color(0xFFF4FAFF),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFF8F9FF),
    onSurface: Color(0xFF0B1C30),
    onSurfaceVariant: Color(0xFF414752),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEFF4FF),
    surfaceContainer: Color(0xFFE5EEFF),
    surfaceContainerHigh: Color(0xFFDCE9FF),
    surfaceContainerHighest: Color(0xFFD3E4FE),
    outline: Color(0xFF717784),
    outlineVariant: Color(0xFFC1C6D4),
    inverseSurface: Color(0xFF213145),
    onInverseSurface: Color(0xFFEAF1FF),
    inversePrimary: Color(0xFFA8C8FF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF005EB4),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA8C8FF),
    onPrimary: Color(0xFF00315F),
    primaryContainer: Color(0xFF1972D2),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFC0C1FF),
    onSecondary: Color(0xFF16179E),
    secondaryContainer: Color(0xFF6063EE),
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFF7BD0FF),
    onTertiary: Color(0xFF003549),
    tertiaryContainer: Color(0xFF007BA6),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0F172A),
    onSurface: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFFC1C6D4),
    surfaceContainerLowest: Color(0xFF0B1220),
    surfaceContainerLow: Color(0xFF161F33),
    surfaceContainer: Color(0xFF1E293B),
    surfaceContainerHigh: Color(0xFF26334A),
    surfaceContainerHighest: Color(0xFF334155),
    outline: Color(0xFF8A91A0),
    outlineVariant: Color(0xFF334155),
    inverseSurface: Color(0xFFEAF1FF),
    onInverseSurface: Color(0xFF0B1C30),
    inversePrimary: Color(0xFF0059AC),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFFA8C8FF),
  );

  /// Escala tipográfica explícita en Inter.
  ///
  /// El color se aplica en [_build] con [TextTheme.apply], no aquí: un
  /// [TextStyle] sin color se pinta negro, y ya causó una regresión real en
  /// modo oscuro cuando el color se dejó para "más adelante".
  static TextTheme _textTheme() {
    TextStyle style({
      required double size,
      required double height,
      required FontWeight weight,
      double spacing = 0,
    }) => TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: spacing,
    );

    return TextTheme(
      displayLarge: style(size: 32, height: 40, weight: FontWeight.w700),
      displayMedium: style(size: 28, height: 36, weight: FontWeight.w700),
      displaySmall: style(size: 24, height: 32, weight: FontWeight.w700),
      headlineLarge: style(size: 32, height: 40, weight: FontWeight.w700),
      headlineMedium: style(size: 22, height: 28, weight: FontWeight.w600),
      headlineSmall: style(size: 18, height: 24, weight: FontWeight.w600),
      titleLarge: style(size: 18, height: 24, weight: FontWeight.w600),
      titleMedium: style(size: 16, height: 24, weight: FontWeight.w600),
      titleSmall: style(size: 14, height: 20, weight: FontWeight.w600),
      bodyLarge: style(size: 16, height: 24, weight: FontWeight.w400),
      bodyMedium: style(size: 14, height: 20, weight: FontWeight.w400),
      bodySmall: style(size: 12, height: 16, weight: FontWeight.w400),
      labelLarge: style(size: 14, height: 20, weight: FontWeight.w600),
      labelMedium: style(size: 12, height: 16, weight: FontWeight.w500),
      labelSmall: style(
        size: 11,
        height: 14,
        weight: FontWeight.w600,
        spacing: 0.2,
      ),
    );
  }

  /// `headlineLarge` reducido para pantallas de menos de 600 px, según el
  /// sistema de diseño. Se usa explícitamente donde haga falta, en vez de
  /// sustituir el estilo global, porque solo afecta a un puñado de títulos.
  static TextStyle compactHeadlineLarge(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: 26,
      height: 32 / 26,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }
}
