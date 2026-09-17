import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Lista de tarjetas que pasa a varias columnas cuando hay ancho para ello.
///
/// En móvil se comporta como una lista normal de una columna. En una pantalla
/// apaisada grande, una sola columna deja el contenido en una tira estrecha con
/// dos franjas vacías a los lados, así que aquí se reparte en columnas.
///
/// Se usa `Wrap` y no `GridView` a propósito: las tarjetas de receta tienen
/// altura variable según el texto, y una rejilla obligaría a fijar una
/// proporción, con el consiguiente riesgo de recortes o huecos.
class ResponsiveCardList extends StatelessWidget {
  const ResponsiveCardList({
    super.key,
    required this.children,
    this.minColumnWidth = 340,
    this.maxColumns = 3,
    this.spacing = Spacing.md,
    this.padding = EdgeInsets.zero,
    this.scrollable = true,
  });

  final List<Widget> children;

  /// Ancho mínimo que debe tener cada columna para que se añada otra.
  final double minColumnWidth;

  /// Tope de columnas. Más de tres obliga a barrer la vista de lado a lado.
  final int maxColumns;

  final double spacing;
  final EdgeInsetsGeometry padding;

  /// Si ya está dentro de algo que desplaza, conviene ponerlo a `false`.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;

        // Sin ancho conocido no se puede repartir: una columna y a correr.
        if (!available.isFinite || available <= 0) {
          return _singleColumn();
        }

        var columns = (available / minColumnWidth).floor();
        columns = columns.clamp(1, maxColumns);
        if (columns == 1) return _singleColumn();

        final columnWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: columnWidth, child: child),
          ],
        );
      },
    );

    final padded = Padding(padding: padding, child: content);
    if (!scrollable) return padded;
    return SingleChildScrollView(child: padded);
  }

  Widget _singleColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}
