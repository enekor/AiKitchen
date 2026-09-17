import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Centra el contenido y le pone un ancho máximo.
///
/// Sin esto, en una ventana de escritorio una línea de texto ocupa todo el
/// ancho disponible y resulta incómoda de leer. El padding lateral también se
/// adapta: apretado en móvil, holgado en pantallas grandes.
class ContentShell extends StatelessWidget {
  const ContentShell({
    super.key,
    required this.child,
    this.maxWidth = ContentWidth.readable,
    this.padding,
  });

  /// Variante para rejillas y listas, donde varias columnas sí aprovechan
  /// el ancho extra.
  const ContentShell.wide({
    super.key,
    required this.child,
    this.padding,
  }) : maxWidth = ContentWidth.wide;

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = Breakpoints.isCompact(width) ? Spacing.lg : Spacing.xxl;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}

/// Igual que [ContentShell] pero para el hijo de un `CustomScrollView`.
///
/// Los slivers no admiten un `Center` normal encima, así que el ancho se
/// limita con el sliver equivalente.
class SliverContentShell extends StatelessWidget {
  const SliverContentShell({
    super.key,
    required this.sliver,
    this.maxWidth = ContentWidth.readable,
  });

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = Breakpoints.isCompact(width) ? Spacing.lg : Spacing.xxl;
    final extra = width > maxWidth ? (width - maxWidth) / 2 : 0.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontal + extra),
      sliver: sliver,
    );
  }
}
