import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/ui/app_card.dart';
import 'package:aikitchen/widgets/ui/recipe_meta_row.dart';
import 'package:flutter/material.dart';

/// Tarjeta de receta sin fotografía.
///
/// Las recetas generadas por IA no tienen imagen y el modelo no la guarda, así
/// que esta tarjeta se apoya solo en tipografía y color. La única tarjeta con
/// foto de la aplicación es [WebRecipeCard], para los resultados de internet,
/// que sí traen una dirección de imagen.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.badge,
    this.trailing,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  /// Insignia opcional en la esquina, por ejemplo el origen de la receta.
  final Widget? badge;

  /// Acción extra a la derecha del título, por ejemplo un botón de "cocinar".
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null) ...[badge!, const SizedBox(width: Spacing.sm)],
              Expanded(
                child: Text(
                  recipe.nombre,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onToggleFavorite != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isFavorite ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: isFavorite ? 'Quitar de favoritos' : 'Guardar',
                  onPressed: onToggleFavorite,
                ),
            ],
          ),
          if (recipe.descripcion.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              recipe.descripcion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(child: RecipeMetaRow(recipe: recipe)),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}
