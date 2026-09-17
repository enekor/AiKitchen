import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Contenedor base del sistema de diseño: contorno técnico de 1 px, radio 12
/// y sin sombra. Todas las tarjetas de la aplicación se construyen sobre este
/// componente en lugar de declarar su propio `BoxDecoration`.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      color: color ?? theme.colorScheme.surfaceContainerLowest,
      borderRadius: AppRadius.medium,
      border: Border.all(color: theme.colorScheme.outlineVariant),
    );

    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }

    // El decorado va en el Material para que el ripple del InkWell quede
    // recortado por el mismo radio, en vez de desbordar las esquinas.
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: color ?? theme.colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
