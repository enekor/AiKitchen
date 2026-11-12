import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/material.dart';

/// Foto del plato de una receta. Si no tiene, o la imagen está dañada,
/// muestra [fallback]; por defecto, nada, para que la tarjeta quede igual que
/// las recetas sin foto.
class RecipePhoto extends StatelessWidget {
  const RecipePhoto({
    super.key,
    required this.recipe,
    this.aspectRatio = 16 / 9,
    this.borderRadius = BorderRadius.zero,
    this.fallback = const SizedBox.shrink(),
  });

  final Recipe recipe;
  final double aspectRatio;
  final BorderRadius borderRadius;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final bytes = recipe.fotoBytes;
    if (bytes == null) return fallback;

    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          semanticLabel: 'Foto de ${recipe.nombre}',
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
